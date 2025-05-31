//
//  Entities.swift
//  GymMembershipApp
//
//  Created by imac4 on 31/05/2025.
//

import Foundation

// MARK: - Plan
struct Plan: Codable, Identifiable {
    let id: Int
    let name: String
    let price: Double
    let duration_months: Int

    // For display
    var formattedPrice: String {
        String(format: "$%.2f", price)
    }
    var subtitle: String {
        "\(duration_months)-month"
    }
}

// MARK: - CreatePaymentResponse
struct CreatePaymentResponse: Codable {
    let payment_id: Int
    let square_id: String
    let status: String
}

// MARK: - MembershipData & MembershipResponse
struct MembershipData: Codable {
    let id: Int
}

struct MembershipResponse: Codable {
    let message: String
    let membership: MembershipData
}

// MARK: - CheckoutLinkResponse
struct CheckoutLinkResponse: Codable {
    let checkout_url: String   // The Square-hosted checkout URL
    let payment_id: Int?
}

// MARK: - AuthResponse
struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

// MARK: - DashboardResponse
struct DashboardResponse: Codable {
    let status: String?
    let qr: String?
    let message: String?   // To catch “Unauthenticated.”
}

// MARK: - Payment (used in PaymentHistory)
typealias PaymentID = Int

struct Payment: Codable, Identifiable {
    let id: PaymentID
    let amount: Double
    let status: String
    let created_at: String   // ISO8601 timestamp

    var formattedAmount: String {
        String(format: "$%.2f", amount)
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()
    var date: Date? {
        Payment.isoFormatter.date(from: created_at)
    }

    var formattedDate: String {
        guard let date = date else { return "" }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}

// MARK: - EmptyResponse
/// A placeholder type for APIs that return no meaningful JSON payload.
struct EmptyResponse: Decodable { }
