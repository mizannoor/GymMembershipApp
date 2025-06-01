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
    @StateObject private var vm = DashboardViewModel()

    @State private var showCancelAlert       = false
    @State private var cancelErrorMessage: String?

    // ───── Toast state ───────────────────────────────────────────
    @State private var showPaymentToast       = false
    @State private var toastOpacity: Double   = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // ─────────────────────────────────────────────────────────────
                // Main VStack content
                VStack(spacing: 24) {
                    // 1) Status + QR + Start/End Dates
                    DashboardStatusWithDatesView(
                        statusText:    vm.statusText,
                        base64QRCode:  vm.qrBase64,
                        startDateText: vm.startDateText,
                        endDateText:   vm.endDateText
                    )

                    Spacer()

                    // 2) Buttons at Bottom
                    VStack(spacing: 12) {
                        // “Subscribe Membership” always visible
                        NavigationLink {
                            PlanSelectionView()
                        } label: {
                            Text("Subscribe Membership")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryActionButtonStyle())

                        // Show “Cancel Membership” only if status == “Active”
                        if vm.statusText.lowercased() == "active" {
                            Button("Cancel Membership") {
                                showCancelAlert = true
                            }
                            .foregroundColor(.red)
                            .alert(isPresented: $showCancelAlert) {
                                Alert(
                                    title: Text("Cancel Membership"),
                                    message: Text("Are you sure you want to cancel your active membership?"),
                                    primaryButton: .destructive(Text("Yes, Cancel")) {
                                        Task {
                                            do {
                                                try await APIClient.shared.cancelSubscription()
                                                vm.loadDashboard()
                                            } catch {
                                                cancelErrorMessage = error.localizedDescription
                                            }
                                        }
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        }
                    }
                }
                .loadingErrorEmpty(
                    isLoading:    vm.isLoading,
                    errorMessage: vm.errorMessage ?? cancelErrorMessage,
                    isEmpty:      false,
                    emptyMessage: ""
                )
                .padding()
                .navigationTitle("Dashboard")
                .toolbar {
                    // Refresh button
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            vm.loadDashboard()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .onAppear(perform: vm.loadDashboard)
                // ─────────────────────────────────────────────────────────────

                // ───── Toast overlay ───────────────────────────────────
                if showPaymentToast {
                    VStack {
                        ToastView(message: "Payment completed successfully")
                            .opacity(toastOpacity)
                            .onAppear {
                                withAnimation(.easeIn(duration: 0.3)) {
                                    toastOpacity = 1
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        toastOpacity = 0
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        showPaymentToast = false
                                    }
                                }
                            }
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            // ─────────────────────────────────────────────────────────────
            // Listen for .paymentDidComplete notification
            .onReceive(NotificationCenter.default.publisher(for: .paymentDidComplete)) { _ in
                showPaymentToast = true
                toastOpacity     = 0
            }

            // Force logout whenever vm.errorMessage contains "Unauthenticated"
            .onChange(of: vm.errorMessage) { newError in
                if let msg = newError, msg.contains("Unauthenticated") {
                    authVM.signOut()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .unauthenticated)) { _ in
                authVM.signOut()
            }
        }
    }
}

// MARK: - DashboardStatusWithDatesView
struct DashboardStatusWithDatesView: View {
    let statusText:    String
    let base64QRCode:  String?
    let startDateText: String
    let endDateText:   String

    var body: some View {
        VStack(spacing: 16) {
            Text("Membership Status:")
                .font(.headline)

            Text(statusText)
                .font(.title2)
                .bold()

            if let qrString = base64QRCode,
               let data     = Data(base64Encoded: qrString),
               let uiImage  = UIImage(data: data)
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }

            HStack(spacing: 32) {
                VStack(alignment: .leading) {
                    Text("Start Date:")
                        .font(.subheadline).bold()
                    Text(startDateText)
                        .font(.subheadline)
                }
                VStack(alignment: .leading) {
                    Text("End Date:")
                        .font(.subheadline).bold()
                    Text(endDateText)
                        .font(.subheadline)
                }
            }
            .padding(.top, 12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let authVM = AuthViewModel()
        DashboardView()
            .environmentObject(authVM)
    }
}
