//
//  GoogleSignInButton.swift
//  GymMembershipApp
//
//  Created by imac4 on 25/05/2025.
//

import SwiftUI
import GoogleSignIn

struct GoogleSignInButton: UIViewRepresentable {
  func makeUIView(context: Context) -> GIDSignInButton {
    let btn = GIDSignInButton()
    btn.style = .wide        // or .iconOnly / .standard
    return btn
  }
  func updateUIView(_ uiView: GIDSignInButton, context: Context) {}
}
