//
//  ViewModels.swift
//  GymMembershipApp
//
//  Created by imac4 on 31/05/2025.
//

import Foundation
import Combine
import SwiftUI
import GoogleSignIn

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
            // Because the protocol is @MainActor, these property changes are on the main actor
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


// MARK: - AuthViewModel

/// Manages Google Sign-In authentication state.
@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false

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
        // Only check that an ID token exists (we don’t need the local variable).
        guard user.idToken?.tokenString != nil else { return }
        // Here you’d exchange the ID token for your backend JWT in your View/Coordinator.
        DispatchQueue.main.async {
            self.isAuthenticated = true
        }
    }

    func signInSucceeded(with token: String) {
        KeychainHelper.standard.save(
            Data(token.utf8),
            service: Constants.keychainService,
            account: Constants.keychainAccount
        )
        isAuthenticated = true
    }

    func signOut() {
        KeychainHelper.standard.save(
            Data(),
            service: Constants.keychainService,
            account: Constants.keychainAccount
        )
        isAuthenticated = false
    }
}


// MARK: - PlanViewModel

/// Fetches and subscribes to membership plans.
@MainActor
class PlanViewModel: ObservableObject, Loadable {
    @Published var plans: [Plan] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Loads available plans from the server.
    func loadPlans() {
        perform({
            try await APIClient.shared.fetchPlans()
        }) { fetchedPlans in
            self.plans = fetchedPlans
        }
    }

    /// Subscribes to the given plan.
    func subscribe(to plan: Plan) {
        perform({
            try await APIClient.shared.subscribe(to: plan.id)
        }) { _ in
            // Post-subscription logic (e.g. notifications) can go here
        }
    }
}


// MARK: - DashboardViewModel

/// Retrieves dashboard status and QR code.
@MainActor
class DashboardViewModel: ObservableObject, Loadable {
    @Published var statusText: String = ""
    @Published var qrImage: Image?
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Fetches current user’s dashboard data.
    func loadDashboard() {
        perform({
            try await APIClient.shared.fetchDashboard()
        }) { dash in
            self.statusText = (dash.status ?? "Unknown").capitalized

            // Decode Base64 QR string into SwiftUI Image
            if let base64String = dash.qr,
               let data = Data(base64Encoded: base64String),
               let uiImage = UIImage(data: data) {
                self.qrImage = Image(uiImage: uiImage)
            } else {
                self.qrImage = nil
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
