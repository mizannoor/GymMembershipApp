//
//  GoogleButton.swift
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


/// A simple SwiftUI-styled Google button
struct GoogleLoginButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image("google_logo")
                    .resizable()
                    .frame(width: 24, height: 24)
                Text("Sign in with Google")
                    .font(.headline)
            }
            .foregroundColor(.black)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}
