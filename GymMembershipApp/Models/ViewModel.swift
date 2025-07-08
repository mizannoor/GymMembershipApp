//
//  ViewModel.swift
//  GymMembershipApp
//
//  Created by imac4 on 31/05/2025.
//

import Foundation
import Combine
import SwiftUI
import GoogleSignIn
import FirebaseAnalytics
import FirebaseCrashlytics

// MARK: - Loadable Protocol

@MainActor
/// A protocol for view models that manage loading/error state. All requirements live on the main actor.
protocol Loadable: ObservableObject {
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
}

extension Loadable {
    /// Executes an async task while managing `isLoading` and `errorMessage`.
    ///
    /// - Parameters:
    ///   - work: An async throwing closure that returns a value of type `T`.
    ///   - onSuccess: A closure that receives the value `T` if `work` succeeds.
    func perform<T>(
        _ work: @escaping () async throws -> T,
        onSuccess: @escaping (T) -> Void
    ) {
        Task {
            self.isLoading = true
            self.errorMessage = nil

            do {
                let result = try await work()
                self.isLoading = false
                onSuccess(result)
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - ProfileViewModel
// ProfileViewModel.swift
@MainActor
class ProfileViewModel: ObservableObject, Loadable {
    // MARK: - Published Properties

    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Load Profile

    /// Fetches the authenticated user’s basic info (id, name, email).
    func loadProfile() {
        perform({
            try await APIClient.shared.fetchProfile()
        }) { fetchedUser in
            self.user = fetchedUser
        }
    }

    // MARK: - Delete Account

    /// Sends a DELETE request to remove the current user (and related data).
    /// - Parameter onSuccess: Called if deletion succeeds; typically used to sign out.
    func deleteAccount(onSuccess: @escaping () -> Void) {
        perform({
            try await APIClient.shared.deleteAccount()
        }) { _ in
            
            Analytics.logEvent("account_deleted", parameters: [
                "user_id": self.user?.id ?? 0
            ])
            
            onSuccess()

        }
    }
}

// MARK: - AuthViewModel

/// Manages Google Sign-In authentication state.
@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String? = nil

    init() {
        // Attempt silent restore
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                if let user = user, error == nil {
                    self.handle(user: user)
                }
            }
        }
    }

    private func handle(user: GIDGoogleUser) {
        guard user.idToken?.tokenString != nil else { return }
        DispatchQueue.main.async {
            self.isAuthenticated = true
        }
    }

    func signInSucceeded(with token: String) {
        do {
            KeychainHelper.standard.save(
                Data(token.utf8),
                service: Constants.keychainService,
                account: Constants.keychainAccount
            )
            isAuthenticated = true
            Analytics.logEvent("login_success", parameters: [
                "method": "google"
            ])
        } catch {
            Crashlytics.crashlytics().record(error: error)
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        do {
            Analytics.logEvent("logout", parameters: [
                "method": "manual"
            ])
            KeychainHelper.standard.save(
                Data(),
                service: Constants.keychainService,
                account: Constants.keychainAccount
            )
            isAuthenticated = false
        } catch {
            Crashlytics.crashlytics().record(error: error)
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - PlanViewModel

/// Fetches and subscribes to membership plans, now with a `searchText`
/// property that automatically re-fetches from the server as the user types.
@MainActor
class PlanViewModel: ObservableObject, Loadable {
    // 1) The full array of plans returned from the backend
    @Published var plans: [Plan] = []
    
    // 2) Tracks loading/error state (from Loadable protocol)
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 3) New: the text the user types into the search bar
    @Published var searchText: String = ""
    
    // 4) A place to store any Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // As soon as `searchText` changes, wait 50 ms, ignore duplicates,
        // then call `loadPlans(filter:)` with the latest value.
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] latestText in
                self?.loadPlans(filter: latestText)
            }
            .store(in: &cancellables)
    }
    
    /// Loads all plans (no filter).
    func loadPlans() {
        loadPlans(filter: nil)
    }
    
    /// Loads plans from the server, optionally filtering by name.
    /// - Parameter filter: If non-nil and non-empty, hits `/api/plans?name=<filter>`.
    func loadPlans(filter: String?) {
        let trimmed = filter?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If `trimmed` is an empty string or nil, send nil to fetch all plans.
        let query = (trimmed?.isEmpty == false) ? trimmed : nil
        
        perform({
            try await APIClient.shared.fetchPlans(filter: query)
        }) { fetchedPlans in
            self.plans = fetchedPlans
            
            Analytics.logEvent("plan_search", parameters: [
                "query": self.searchText
            ])

        }
    }
    
    /// Subscribes to the given plan (unchanged from before).
    func subscribe(to plan: Plan) {
        perform({
            try await APIClient.shared.subscribe(to: plan.id)
        }) { _ in
            // Post-subscription logic (e.g. notifications) can go here
            Analytics.logEvent("plan_subscribed", parameters: [
                "plan_id": plan.id,
                "plan_name": plan.name,
                "duration_months": plan.duration_months,
                "price": plan.price
            ])

        }
    }
}


// ──────────────────────────────────────────────────────────────────────────────
// MARK: - DashboardViewModel
@MainActor
class DashboardViewModel: ObservableObject, Loadable {
    @Published var statusText: String = ""
    @Published var qrImage: Image?
    @Published var qrBase64: String?        // <- new: store the raw Base64 string
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var startDateText: String = ""
    @Published var endDateText: String = ""

    private let isoFormatter = ISO8601DateFormatter()
    private let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
    private let dateOnlyFormatter: DateFormatter = {
       let f = DateFormatter()
       f.dateFormat = "yyyy-MM-dd"
       f.locale = Locale(identifier: "en_US_POSIX")
       return f
    }()

    func loadDashboard() {
        perform({
            try await APIClient.shared.fetchDashboard()
        }) { dash in
            // 1) StatusText using membership.status.name...
            if let membership = dash.membership,
               let statusName = membership.status?.name {
                self.statusText = statusName.capitalized
            } else {
                self.statusText = "No Membership"
            }

            // 2) Keep the raw Base64 string
            self.qrBase64 = dash.qr

            // 3) Convert Base64→UIImage→SwiftUI Image
            if let base64String = dash.qr,
               let data = Data(base64Encoded: base64String),
               let uiImage = UIImage(data: data) {
                self.qrImage = Image(uiImage: uiImage)
                
                Analytics.logEvent("qr_displayed", parameters: [
                    "membership_status": self.statusText
                ])

            } else {
                self.qrImage = nil
            }
            
            // 4) Parse start_date / end_date from nested membership
            if let membership = dash.membership {
                if let startsString = membership.startsAt,
                   let date = self.dateOnlyFormatter.date(from: startsString) {
                    self.startDateText = self.dateOnlyFormatter.string(from: date)
                } else {
                    self.startDateText = "—?"
                }

                if let expiresString = membership.expiresAt,
                   let date = self.dateOnlyFormatter.date(from: expiresString) {
                    self.endDateText = self.dateOnlyFormatter.string(from: date)
                } else {
                    self.endDateText = "—?"
                }
            } else {
                self.startDateText = "?—"
                self.endDateText   = "?—"
            }
        }
    }
}

// MARK: - PaymentHistoryViewModel

/// Retrieves payment history.
@MainActor
class PaymentHistoryViewModel: ObservableObject, Loadable {
    @Published var payments: [Payment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Loads all past payments from the server.
    func loadPayments() {
        perform({
            try await APIClient.shared.fetchPayments()
        }) { fetchedPayments in
            self.payments = fetchedPayments
        }
    }
}

// MARK: - CopilotUsageViewModel
@MainActor
class CopilotUsageViewModel: ObservableObject, Loadable {
    @Published var stats: CopilotUsageStats?
    @Published var recentInteractions: [CopilotUsage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    /// Loads copilot usage statistics and recent interactions
    func loadUsageData() {
        perform({
            // For now, return mock data since backend might not be ready
            // TODO: Replace with actual API call when backend is implemented
            try await loadMockData()
        }) { response in
            self.stats = response.stats
            self.recentInteractions = response.recentInteractions
            
            Analytics.logEvent("copilot_usage_viewed", parameters: [
                "total_interactions": response.stats.totalInteractions,
                "satisfaction_rate": response.stats.satisfactionRate
            ])
        }
    }
    
    /// Mock data loader for development/testing
    private func loadMockData() async throws -> CopilotUsageResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let mockStats = CopilotUsageStats(
            totalInteractions: 47,
            totalDuration: 2760, // 46 minutes
            averageDuration: 58.7,
            satisfactionRate: 0.85,
            mostUsedFeature: "workout_suggestion",
            thisWeekInteractions: 8,
            thisMonthInteractions: 23
        )
        
        let mockInteractions = [
            CopilotUsage(
                id: 1,
                userId: 123,
                interactionType: "workout_suggestion",
                timestamp: "2025-07-08T10:30:00Z",
                duration: 75,
                satisfied: true,
                feedback: "Great personalized workout plan!"
            ),
            CopilotUsage(
                id: 2,
                userId: 123,
                interactionType: "nutrition_advice",
                timestamp: "2025-07-07T14:15:00Z",
                duration: 45,
                satisfied: true,
                feedback: "Very helpful meal suggestions"
            ),
            CopilotUsage(
                id: 3,
                userId: 123,
                interactionType: "form_correction",
                timestamp: "2025-07-06T09:45:00Z",
                duration: 90,
                satisfied: false,
                feedback: "Feedback was not very clear"
            ),
            CopilotUsage(
                id: 4,
                userId: 123,
                interactionType: "workout_suggestion",
                timestamp: "2025-07-05T16:20:00Z",
                duration: 60,
                satisfied: true,
                feedback: nil
            ),
            CopilotUsage(
                id: 5,
                userId: 123,
                interactionType: "nutrition_advice",
                timestamp: "2025-07-04T11:10:00Z",
                duration: 30,
                satisfied: true,
                feedback: "Perfect timing for my diet goals"
            )
        ]
        
        return CopilotUsageResponse(
            stats: mockStats,
            recentInteractions: mockInteractions,
            message: "Mock data loaded successfully"
        )
    }
    
    /// Logs a new copilot interaction
    func logCopilotInteraction(type: String, duration: Int, satisfied: Bool, feedback: String? = nil) {
        Analytics.logEvent("copilot_interaction", parameters: [
            "interaction_type": type,
            "duration": duration,
            "satisfied": satisfied,
            "has_feedback": feedback != nil
        ])
        
        // For now, just log to analytics. Backend integration can be added later.
        // TODO: Add actual API call to log interaction when backend is ready
        
        // Add a mock interaction to the beginning of the list for immediate feedback
        let newInteraction = CopilotUsage(
            id: Int.random(in: 1000...9999),
            userId: 123,
            interactionType: type,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            duration: duration,
            satisfied: satisfied,
            feedback: feedback
        )
        
        // Insert at the beginning of recent interactions
        recentInteractions.insert(newInteraction, at: 0)
        
        // Update stats if available
        if var currentStats = stats {
            currentStats = CopilotUsageStats(
                totalInteractions: currentStats.totalInteractions + 1,
                totalDuration: currentStats.totalDuration + duration,
                averageDuration: Double(currentStats.totalDuration + duration) / Double(currentStats.totalInteractions + 1),
                satisfactionRate: currentStats.satisfactionRate, // Simplified for mock
                mostUsedFeature: currentStats.mostUsedFeature,
                thisWeekInteractions: currentStats.thisWeekInteractions + 1,
                thisMonthInteractions: currentStats.thisMonthInteractions + 1
            )
            stats = currentStats
        }
        
        // Keep only the most recent 10 interactions for UI performance
        if recentInteractions.count > 10 {
            recentInteractions = Array(recentInteractions.prefix(10))
        }
    }
}
