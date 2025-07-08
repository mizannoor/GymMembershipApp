//
//  Entities.swift
//  GymMembershipApp
//
//  Created by imac4 on 31/05/2025.
//

import Foundation

// MARK: - User
/// Represents the authenticated user’s basic info.
struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
}

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

// MARK: - MembershipData
/// Represents a single row in the “memberships” table:
///   • id (primary key)
///   • user_id (foreign key to users)
///   • plan_id (foreign key to membership_plans)
///   • status_id (foreign key to status table, e.g. active/inactive)
///   • starts_at (date)
///   • expires_at (date)
struct MembershipData: Codable {
    let id: Int
    let userId: Int
    let planId: Int
    let statusId: Int
    let status: Status?
    let startsAt: String?    // ISO8601 or “YYYY-MM-DD” format, depending on backend
    let expiresAt: String?   // ISO8601 or “YYYY-MM-DD” format, depending on backend

    private enum CodingKeys: String, CodingKey {
        case id
        case userId    = "user_id"
        case planId    = "plan_id"
        case statusId  = "status_id"
        case status    = "status"
        case startsAt  = "starts_at"
        case expiresAt = "expires_at"
    }
}

// MARK: - MembershipResponse
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

// ──────────────────────────────────────────────────────────────────────────────
// MARK: - DashboardResponse
/// Now includes a nested `membership` object instead of flat `start_date`/`end_date`.
struct DashboardResponse: Codable {
    let status: String?
    let qr: String?
    let message: String?

    // New: a nested membership object:
    let membership: MembershipData?

    private enum CodingKeys: String, CodingKey {
        case status
        case qr
        case message
        case membership
    }
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

// MARK: - Status
/// Represents a row in your `status` table:
///   • id          (e.g. 1)
///   • name        (e.g. "active")
///   • description (e.g. "Currently active")
struct Status: Codable, Identifiable {
    let id: Int
    let name: String
    
    /// We use `descriptionText` in Swift to avoid colliding with Swift’s
    /// built-in `description` property. It nonetheless maps to the JSON key `"description"`.
    let descriptionText: String

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case descriptionText = "description"
    }
}


// MARK: - CopilotUsage
/// Represents copilot agent usage statistics for a user
struct CopilotUsage: Codable, Identifiable {
    let id: Int
    let userId: Int
    let interactionType: String // e.g., "workout_suggestion", "nutrition_advice", "form_correction"
    let timestamp: String       // ISO8601 timestamp
    let duration: Int          // Duration in seconds
    let satisfied: Bool        // Whether user was satisfied with the interaction
    let feedback: String?      // Optional user feedback
    
    private enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case interactionType = "interaction_type"
        case timestamp
        case duration
        case satisfied
        case feedback
    }
    
    var formattedTimestamp: String {
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: timestamp) else { return timestamp }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - CopilotUsageStats
/// Summary statistics for copilot usage
struct CopilotUsageStats: Codable {
    let totalInteractions: Int
    let totalDuration: Int      // Total duration in seconds
    let averageDuration: Double // Average duration in seconds
    let satisfactionRate: Double // Percentage of satisfied interactions
    let mostUsedFeature: String?
    let thisWeekInteractions: Int
    let thisMonthInteractions: Int
    
    private enum CodingKeys: String, CodingKey {
        case totalInteractions = "total_interactions"
        case totalDuration = "total_duration" 
        case averageDuration = "average_duration"
        case satisfactionRate = "satisfaction_rate"
        case mostUsedFeature = "most_used_feature"
        case thisWeekInteractions = "this_week_interactions"
        case thisMonthInteractions = "this_month_interactions"
    }
    
    var formattedTotalDuration: String {
        let hours = totalDuration / 3600
        let minutes = (totalDuration % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedSatisfactionRate: String {
        String(format: "%.1f%%", satisfactionRate * 100)
    }
}

// MARK: - CopilotUsageResponse
/// Response structure for copilot usage API
struct CopilotUsageResponse: Codable {
    let stats: CopilotUsageStats
    let recentInteractions: [CopilotUsage]
    let message: String?
}

// MARK: - EmptyResponse
/// A placeholder type for APIs that return no meaningful JSON payload.
struct EmptyResponse: Decodable { }
