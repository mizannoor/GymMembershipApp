//
//  ContentView.swift
//  GymMembershipApp
//
//  Created by imac4 on 09/05/2025.
//

// ContentView.swift

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var isMenuOpen = false
    @State private var selection: MenuOption = .dashboard
    @State private var lastInteraction = Date()
    @State private var sessionTimer: Timer? = nil
    let sessionTimeout: TimeInterval = 300 // 5 minutes

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                authenticatedView
                    .onAppear { startSessionTimer() }
                    .onDisappear { stopSessionTimer() }
                    .background(
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in resetSessionTimer() }
                            )
                            .simultaneousGesture(
                                TapGesture().onEnded { resetSessionTimer() }
                            )
                    )
            } else {
                // Show SignInView for unauthenticated users
                SignInView()
                    .environmentObject(authVM)
            }
        }
    }

    @ViewBuilder
    private var authenticatedView: some View {
        ZStack {
            // Side menu
            if isMenuOpen {
                SideMenu(isOpen: $isMenuOpen, selection: $selection)
                    .transition(.move(edge: .leading))
            }

            // Main content area
            mainView
                .scaleEffect(isMenuOpen ? 0.9 : 1)
                .offset(x: isMenuOpen ? 240 : 0)
                .disabled(isMenuOpen)
        }
        .animation(.easeInOut, value: isMenuOpen)
    }

    @ViewBuilder
    private var mainView: some View {
        NavigationView {
            Group {
                switch selection {
                    case .dashboard:
                        DashboardView()
                    case .plans:
                        PlanSelectionView()
                    case .payments:
                        PaymentHistoryView()
                    case .account:                                       // <-- new
                        ProfileView()
                    case .signOut:
                        // Perform sign out and return to dashboard
                        Color.clear.onAppear {
                            authVM.signOut()
                            selection = .dashboard
                        }
                }
            }
            .navigationBarTitle(selection.rawValue, displayMode: .inline)
            .navigationBarItems(leading: Button(action: {
                withAnimation { isMenuOpen.toggle() }
            }) {
                Image(systemName: "line.horizontal.3").font(.title)
                    .imageScale(.large)
            })
        }
    }

    // MARK: - Session Timeout Logic
    private func startSessionTimer() {
        stopSessionTimer()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let interval = Date().timeIntervalSince(lastInteraction)
            print("Last interaction: \(lastInteraction), Interval: \(interval)")
            if interval > sessionTimeout {
                sessionTimer?.invalidate()
                sessionTimer = nil
                authVM.signOut()
            }
        }
    }
    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }
    private func resetSessionTimer() {
        lastInteraction = Date()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
