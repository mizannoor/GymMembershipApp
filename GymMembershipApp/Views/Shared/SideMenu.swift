//
//  SideMenu.swift
//  GymMembershipApp
//
//  Created by imac4 on 25/05/2025.
//

// SideMenu.swift

import SwiftUI

struct SideMenu: View {
    @Binding var isOpen: Bool
    @Binding var selection: MenuOption
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(MenuOption.allCases) { option in
                HStack(spacing: 12) {
                    Image(systemName: option.iconName)
                        .frame(width: 24, height: 24)
                    Text(option.rawValue)
                        .font(.headline)
                }
                .padding(.vertical, 8)
                .onTapGesture {
                    withAnimation {
                        isOpen = false
                        if option == .signOut {
                            authVM.signOut()
                        } else {
                            selection = option
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.top, 100)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }
}
