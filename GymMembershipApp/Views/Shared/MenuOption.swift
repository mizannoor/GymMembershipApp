//
//  MenuOption.swift
//  GymMembershipApp
//
//  Created by imac4 on 25/05/2025.
//


import Foundation
import SwiftUI

enum MenuOption: String, CaseIterable, Identifiable {
    case dashboard
    case plans
    case payments
    case account    // <-- new
    case signOut

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .dashboard: return "house"
        case .plans:     return "doc.plaintext"
        case .payments:  return "creditcard"
        case .account:   return "person.circle"   // <-- new
        case .signOut:   return "arrow.backward.square"
        }
    }

    var rawValue: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .plans:     return "Plans"
        case .payments:  return "Payments"
        case .account:   return "Account"         // <-- new
        case .signOut:   return "Sign Out"
        }
    }
}
