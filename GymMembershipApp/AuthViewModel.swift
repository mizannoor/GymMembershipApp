//
//  AuthViewModel.swift
//  GymMembershipApp
//
//  Created by imac4 on 09/05/2025.
//
//
//  AuthViewModel.swift
//  GymMembershipApp
//

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
