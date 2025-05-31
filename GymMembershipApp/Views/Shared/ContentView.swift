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

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                authenticatedView
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
                Image(systemName: "line.horizontal.3")
                    .imageScale(.large)
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
