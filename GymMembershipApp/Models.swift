//
//  Models.swift
//  GymMembershipApp
//
//  Created by imac4 on 27/05/2025.
//

import Foundation

/// Matches your backend’s JSON after creating a payment
struct CreatePaymentResponse: Codable {
    let payment_id: Int
    let square_id:  String
    let status:      String
}

struct MembershipResponse: Codable {
  let message: String
  let membership: MembershipData
}

struct MembershipData: Codable {
  let id: Int
}

/// Matches `{ "checkout_url": "https://..." }`
// MARK: – Response model for your checkout‐link endpoint
struct CheckoutLinkResponse: Codable {
  let checkout_url: String   // the Square hosted-checkout URL
  let payment_id: Int?        // your DB’s PK for the new “pending” Payment
}
