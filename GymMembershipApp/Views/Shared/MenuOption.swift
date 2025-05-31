//
//  MenuOption.swift
//  GymMembershipApp
//
//  Created by imac4 on 25/05/2025.
//

// MenuOption.swift

import SwiftUI

enum MenuOption: String, CaseIterable, Identifiable {
    case dashboard   = "Dashboard"
    case plans       = "Plans"
    case payments    = "Payments"
    case signOut     = "Sign Out"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .dashboard: return "speedometer"
        case .plans:     return "list.bullet"
        case .payments:  return "creditcard"
        case .signOut:   return "arrow.backward.circle"
        }
    }
}
