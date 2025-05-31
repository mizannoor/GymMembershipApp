//
//  SignInView.swift
//  GymMembershipApp
//
//  Created by imac4 on 09/05/2025.
//
// SignInView.swift
import SwiftUI
import GoogleSignIn


struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24)  {
            Spacer()
            Text("Welcome to GymMembershipApp!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .padding(.top, 40)
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                // Adjust width/height as needed.
                .frame(width: 200, height: 200)

            Text("By signing up, you agree to the Terms of Service and Privacy Policy.")
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 40)
            
            GoogleLoginButton {
                signIn()
            }
            .disabled(isSigningIn).padding(.horizontal, 24)

            if let msg = errorMessage {
                Text(msg)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .padding(.bottom, 40)
                    .navigationTitle("Sign In")
    }

    private func signIn() {
        // 1) Try silent restore if possible
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            isSigningIn = true
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                isSigningIn = false
                if let user = user, error == nil {
                    handleSignIn(user)
                } else {
                    // silent restore failed, show the picker
                    presentGooglePicker()
                }
            }
        } else {
            // no previous session, show the picker
            presentGooglePicker()
        }
    }

    private func presentGooglePicker() {
        // Grab the key window’s root view controller
        guard
            let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let rootVC = scene.windows.first(where: \.isKeyWindow)?.rootViewController
        else {
            errorMessage = "Unable to access root view controller"
            return
        }

        isSigningIn = true
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            defer { isSigningIn = false }

            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            guard let user = result?.user else {
                errorMessage = "Google sign-in failed"
                return
            }
            handleSignIn(user)
        }
    }

    private func handleSignIn(_ user: GIDGoogleUser) {
        guard let idToken = user.idToken?.tokenString else {
            errorMessage = "Failed to retrieve ID token"
            return
        }

        APIClient.shared.authenticateWithGoogle(idToken: idToken) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let auth):
                    authVM.signInSucceeded(with: auth.access_token)
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .environmentObject(AuthViewModel())
    }
}
