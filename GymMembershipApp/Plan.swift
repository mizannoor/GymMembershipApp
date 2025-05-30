//
//  Plan.swift
//  GymMembershipApp
//
//  Created by imac4 on 25/05/2025.
//

import Foundation

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
