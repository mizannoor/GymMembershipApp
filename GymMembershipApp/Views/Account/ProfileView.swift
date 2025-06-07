//
//  ProfileView.swift
//  GymMembershipApp
//
//  Created by imac4 on 01/06/2025.
//

import SwiftUI
import FirebaseAnalytics

struct ProfileView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var vm = ProfileViewModel()

    @State private var showingAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                // 1) Main content, with loading/error/empty handling
                content

                // 2) Overlay a spinner when any loading is in progress (e.g., deleting)
                if vm.isLoading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    ProgressView("Deleting…")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("My Account")
            .toolbar {
                // Optional: Refresh button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        vm.loadProfile()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                vm.loadProfile()
                
                Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                    AnalyticsParameterScreenName: "ProfileView",
                    AnalyticsParameterScreenClass: "ProfileView"
                ])

            }
            .alert("Delete Account", isPresented: $showingAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    vm.deleteAccount {
                        authVM.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone.")
            }
        }
    }

    // MARK: - Content Builder

    @ViewBuilder
    private var content: some View {
        // Build the core content VStack
        let coreContent = VStack(spacing: 24) {
            if let user = vm.user {
                // Profile Image Placeholder
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(radius: 4)
                    .padding(.top, 16)

                // User Name and Email
                VStack(spacing: 8) {
                    Text(user.name)
                        .font(.title2)
                        .bold()

                    Text(user.email)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer()

                // Delete Account Button at bottom
                Button {
                    showingAlert = true
                } label: {
                    Text("Delete Account")
                        .foregroundColor(.red)
                }
                .padding(.bottom, 30)
            }
        }

        // Apply the loading/error/empty modifier to the core content
        coreContent
            .loadingErrorEmpty(
                isLoading: vm.isLoading,
                errorMessage: vm.errorMessage,
                isEmpty: vm.user == nil && !vm.isLoading && vm.errorMessage == nil,
                emptyMessage: "No user data."
            )
    }
}
