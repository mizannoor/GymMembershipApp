//
//  DashboardView.swift
//  GymMembershipApp
//
//  Created by imac4 on 09/05/2025.
//

import SwiftUI

// MARK: - DashboardView
struct DashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var statusText: String = ""
    @State private var qrBase64: String?      // <-- Hold the raw Base64 QR string
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // We use qrBase64 here instead of 'dash'
                DashboardStatusView(
                    statusText: statusText,
                    base64QRCode: qrBase64
                )

                Spacer()

                Button("Sign Out") {
                    authVM.signOut()
                }
                .foregroundColor(.red)
            }
            // Wrap in loading/error container:
            .loadingErrorEmpty(
                isLoading: isLoading,
                errorMessage: errorMessage,
                isEmpty: false,       // We never show an "empty" placeholder here
                emptyMessage: ""
            )
            .padding()
            .navigationTitle("Dashboard")
            .onAppear(perform: loadDashboard)
        }
    }

    // MARK: - Load Dashboard Data
    func loadDashboard() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let dash = try await APIClient.shared.fetchDashboard()
                // 1. Update status text
                statusText = (dash.status ?? "Unknown").capitalized

                // 2. Store raw Base64 into state
                qrBase64 = dash.qr

            } catch {
                errorMessage = "Failed to load: \(error.localizedDescription)"
            }

            isLoading = false
        }
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = AuthViewModel()
        DashboardView()
            .environmentObject(vm)
    }
}
