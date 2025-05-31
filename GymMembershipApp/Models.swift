//
//  Models.swift
//  GymMembershipApp
//
//  Created by imac4 on 27/05/2025.
//

import Foundation
import GoogleSignIn
import Combine
import SwiftUI

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
    guard let idToken = user.idToken?.tokenString else { return }
    // Here you’d exchange the ID token for your backend JWT.
    // On success:
    DispatchQueue.main.async {
      self.isAuthenticated = true
    }
  }

  func signInSucceeded(with token: String) {
    KeychainHelper.standard.save(
      Data(token.utf8),
      service: "gym",
      account: "accessToken"
    )
    isAuthenticated = true
  }

  func signOut() {
    // Remove token and update state
    KeychainHelper.standard.save(
      Data(),
      service: "gym",
      account: "accessToken"
    )
    isAuthenticated = false
  }
}


@MainActor
class PlanViewModel: ObservableObject {
  @Published var plans: [Plan] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  func loadPlans() async {
    isLoading = true
    defer { isLoading = false }
    do {
      let fetched = try await withCheckedThrowingContinuation { cont in
        APIClient.shared.fetchPlans { result in
          cont.resume(with: result)
        }
      }
      plans = fetched
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func subscribe(to plan: Plan) async {
    isLoading = true
    defer { isLoading = false }
    do {
      try await withCheckedThrowingContinuation { cont in
        APIClient.shared.subscribe(to: plan.id) { result in
          cont.resume(with: result.map { _ in () })
        }
      }
      // You could post a Notification or update App state here
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}

struct Plan: Codable, Identifiable {
  let id: Int
  let name: String
  let price: Double
  let duration_months: Int

  // For display
  var formattedPrice: String {
    String(format: "$%.2f", price)
  }
  var subtitle: String {
    "\(duration_months)-month"
  }
}

/// Matches your backend’s JSON after creating a payment
struct CreatePaymentResponse: Codable {
    let payment_id: Int
    let square_id:  String
    let status:      String
}

struct MembershipResponse: Codable {
  let message: String
  let membership: MembershipData
}

struct MembershipData: Codable {
  let id: Int
}

/// Matches `{ "checkout_url": "https://..." }`
// MARK: – Response model for your checkout‐link endpoint
struct CheckoutLinkResponse: Codable {
  let checkout_url: String   // the Square hosted-checkout URL
  let payment_id: Int?        // your DB’s PK for the new “pending” Payment
}


struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}
