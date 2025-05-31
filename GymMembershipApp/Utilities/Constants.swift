//
//  Constants.swift
//  GymMembershipApp
//
//  Created by imac4 on 31/05/2025.
//

// Utilities/Constants.swift

import Foundation

struct Constants {
  // Keychain
  static let keychainService = "gym"
  static let keychainAccount = "accessToken"

  // HTTP Header Keys
  static let authorizationHeader = "Authorization"
  static let contentTypeHeader = "Content-Type"
  static let acceptHeader = "Accept"

  // HTTP Header Values
  static let applicationJson = "application/json"
  static let bearerTokenPrefix = "Bearer "

  // Deep-Link Callback Scheme
  static let callbackURLScheme = "gymmembership"

  // Info.plist Keys
  static let apiBaseURLKey = "API_BASE_URL"
}
