//
//  Untitled.swift
//  GymMembershipApp
//
//  Created by imac4 on 09/05/2025.
//

import Foundation
import Security

final class KeychainHelper {
  static let standard = KeychainHelper()
  private init() {}

  func save(_ data: Data, service: String, account: String) {
    let query = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: account,
      kSecValueData: data
    ] as CFDictionary
    SecItemDelete(query)
    SecItemAdd(query, nil)
  }

  func read(service: String, account: String) -> Data? {
    let query = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: account,
      kSecReturnData: true,
      kSecMatchLimit: kSecMatchLimitOne
    ] as CFDictionary
    var result: AnyObject?
    SecItemCopyMatching(query, &result)
    return result as? Data
  }
}
