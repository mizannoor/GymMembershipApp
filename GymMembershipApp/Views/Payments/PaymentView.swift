//
//  PaymentView.swift
//  GymMembershipApp
//
//  Created by imac4 on 26/05/2025.
//

import SwiftUI
import AuthenticationServices

struct PaymentView: View {
    let membershipId: Int
    let amount: Double

    @Environment(\.presentationMode) private var presentation
    @State private var isLoading        = true
    @State private var checkoutURL      : URL?
    @State private var pendingPaymentId : Int?
    @State private var errorMessage     : String?
    @State private var authSession      : ASWebAuthenticationSession?
    @State private var sessionDelegate  = WebAuthSessionDelegate()
    @State private var showManualOption = false
    @State private var paymentSuccess   = false

    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView("Preparing payment…")
            }
            else if checkoutURL != nil {
                if showManualOption {
                    VStack(spacing: 16) {
                        Text("If payment is completed, tap below to continue.")
                            .multilineTextAlignment(.center)
                        Button("Return to App") {
                            Task {
                                await verifyPaymentStatus()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ProgressView("Redirecting to payment…")
                        .onAppear(perform: startCheckoutSession)
                }
            }
            else if let err = errorMessage {
                Text(err)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .navigationTitle("Payment")
        .task { await loadCheckoutLink() }
        .onReceive(NotificationCenter.default.publisher(for: .paymentDidComplete)) { _ in
            paymentSuccess = true
            presentation.wrappedValue.dismiss()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if !paymentSuccess {
                    showManualOption = true
                }
            }
        }
    }

    private func loadCheckoutLink() async {
        isLoading = true
        errorMessage = nil

        do {
            let resp = try await APIClient.shared.createCheckoutLink(for: membershipId)
            checkoutURL      = URL(string: resp.checkout_url)
            pendingPaymentId = resp.payment_id
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func startCheckoutSession() {
        guard let url = checkoutURL else { return }

        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: Constants.callbackURLScheme
        ) { callback, error in
            DispatchQueue.main.async {
                if let cb = callback,
                   let comps = URLComponents(url: cb, resolvingAgainstBaseURL: false),
                   let items = comps.queryItems {

                    let status = items.first(where:{ $0.name == "status" })?.value
                    let idStr  = items.first(where:{ $0.name == "payment_id" })?.value

                    if let idStr = idStr,
                       let pid = Int(idStr),
                       pid == pendingPaymentId,
                       status == "success" {

                        NotificationCenter.default.post(name: .paymentDidComplete, object: nil)
                    } else {
                        errorMessage = "Payment failed or cancelled."
                    }
                } else {
                    errorMessage = error?.localizedDescription ?? "Payment was cancelled."
                }
            }
        }

        session.presentationContextProvider = sessionDelegate
        session.prefersEphemeralWebBrowserSession = true
        session.start()
        authSession = session
    }

    private func verifyPaymentStatus() async {
        guard let id = pendingPaymentId else { return }

        do {
            let status = try await APIClient.shared.checkPaymentStatus(paymentId: id)
            if status == "success" {
                NotificationCenter.default.post(name: .paymentDidComplete, object: nil)
            } else {
                errorMessage = "Payment not confirmed yet."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private class WebAuthSessionDelegate: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

extension Notification.Name {
    static let paymentDidComplete = Notification.Name("paymentDidComplete")
    static let unauthenticated = Notification.Name("unauthenticated")

}
