//
//  Services.swift
//  GymMembershipApp
//
//  Created by imac4 on 31/05/2025.
//
//  This file merges the networking client (APIClient) and the Keychain helper
//  into one “Services” layer. You can delete the old APIClient.swift and
//  KeychainHelper.swift once this is in place.
//

import Foundation
import Security

// MARK: - KeychainHelper

/// A simple helper to read/write data (e.g. JWT tokens) into the iOS Keychain.
final class KeychainHelper {
    static let standard = KeychainHelper()
    private init() { }

    /// Save data into the Keychain under a given service + account.
    func save(_ data: Data, service: String, account: String) {
        // 1. Create query to delete any existing item first
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account
        ]
        SecItemDelete(query as CFDictionary)

        // 2. Create query to add new item
        let addQuery: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account,
            kSecValueData as String   : data
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    /// Read data from the Keychain for a given service + account.
    func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account,
            kSecReturnData as String  : true,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return (item as? Data)
    }

    /// Delete any stored item for a given service + account.
    func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - APIError

/// A simple enum to represent possible API/networking errors.
enum APIError: Error {
    case invalidURL
    case invalidResponse
    case decodingError(String)
    case serverError(String)
    case notAuthenticated
}

// MARK: - APIClient

/// Centralized networking client for calling your GymMembershipApp backend.
final class APIClient {
    static let shared = APIClient()
    private let baseURL: URL
    private let jsonDecoder = JSONDecoder()

    private init() {
        let urlString =
            Bundle.main.object(forInfoDictionaryKey: Constants.apiBaseURLKey) as! String
        self.baseURL = URL(string: urlString)!
    }
    
    // MARK: - Private Helpers
    
    /// Builds a URLRequest with the given path (appended to baseURL), HTTP method, and optional JSON body.
    private func makeRequest(
        path: String,
        method: String = "GET",
        body: Data? = nil
    ) throws -> URLRequest {
        // 1. Construct URL from baseURL + path
        let url = baseURL.appendingPathComponent(path)
        
        // 2. Initialize URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // 3. Attach JSON headers
        request.setValue(Constants.applicationJson, forHTTPHeaderField: Constants.acceptHeader)
        request.setValue(Constants.applicationJson, forHTTPHeaderField: Constants.contentTypeHeader)
        
        // 4. Attach Bearer token if available
        if let data = KeychainHelper.standard.read(
            service: Constants.keychainService,
            account: Constants.keychainAccount
        ),
           let token = String(data: data, encoding: .utf8),
           !token.isEmpty {
            request.setValue(
                "\(Constants.bearerTokenPrefix)\(token)",
                forHTTPHeaderField: Constants.authorizationHeader
            )
        }
        
        // 5. Assign HTTP body if provided
        request.httpBody = body
        return request
    }
    
    /// Sends a URLRequest, checks for HTTP 2xx status code, and decodes JSON into `T: Decodable`.
    private func sendRequest<T: Decodable>(
      _ request: URLRequest
    ) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 1. Ensure we got an HTTPURLResponse
        guard let httpResp = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // 2. Validate 2xx status code
        guard (200...299).contains(httpResp.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? "No body"
            throw APIError.serverError("Status \(httpResp.statusCode): \(bodyString)")
        }
        
        // 3. Decode JSON into the expected type
        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    // MARK: - Public API Methods (async/await)
    
    /// 1) Exchange Google ID token for backend JWT.
    ///    Note: This remains callback-based because GoogleSignIn SDK uses a closure.
    func authenticateWithGoogle(
        idToken: String,
        completion: @escaping (Result<AuthResponse, Error>) -> Void
    ) {
        let url = baseURL
            .appendingPathComponent("auth")
            .appendingPathComponent("google")
            .appendingPathComponent("token")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(Constants.applicationJson, forHTTPHeaderField: Constants.contentTypeHeader)
        let body = ["id_token": idToken]
        req.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: req) { data, _, err in
            if let err = err {
                return completion(.failure(err))
            }
            guard let data = data else {
                let noDataErr = NSError(
                    domain: "APIClientError",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "No data in authenticateWithGoogle response"]
                )
                return completion(.failure(noDataErr))
            }
            
            // Debug: print raw JSON response
            if let s = String(data: data, encoding: .utf8) {
                print("👉 raw response: \(s)")
            }
            
            do {
                let auth = try self.jsonDecoder.decode(AuthResponse.self, from: data)
                completion(.success(auth))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// 2) Fetch current user’s dashboard data (status + QR).
    func fetchDashboard() async throws -> DashboardResponse {
        let request = try makeRequest(path: "dashboard")
        return try await sendRequest(request)
    }
    
    /// 3) Fetch all membership plans.
    func fetchPlans() async throws -> [Plan] {
        let request = try makeRequest(path: "plans")
        let wrapper: [String: [Plan]] = try await sendRequest(request)
        return wrapper["plans"] ?? []
    }
    
    /// 4) Subscribe to a plan (no return value).
    func subscribe(to planId: Int) async throws {
        let bodyData = try JSONEncoder().encode(["plan_id": planId])
        let request = try makeRequest(path: "subscribe", method: "POST", body: bodyData)
        let _: EmptyResponse = try await sendRequest(request)
    }
    
    /// 5) Create a checkout link for a membership; returns `CheckoutLinkResponse`.
    func createCheckoutLink(for membershipId: Int) async throws -> CheckoutLinkResponse {
        let bodyData = try JSONEncoder().encode(["membership_id": membershipId])
        let request = try makeRequest(path: "payment/checkout-link", method: "POST", body: bodyData)
        return try await sendRequest(request)
    }

    /// 6) Check the status of a payment. Returns a string like "success" or "pending".
    func checkPaymentStatus(paymentId: Int) async throws -> String {
        let request = try makeRequest(path: "payment/\(paymentId)/status")
        let wrapper: [String: String] = try await sendRequest(request)
        guard let status = wrapper["status"] else {
            throw APIError.invalidResponse
        }
        return status
    }
    
    /// 7) Fetch all past payments.
    func fetchPayments() async throws -> [Payment] {
        let request = try makeRequest(path: "payments")
        return try await sendRequest(request)
    }
    
    /// 8) Create a new payment. Returns `CreatePaymentResponse`.
    func createPayment(body: [String: Any]) async throws -> CreatePaymentResponse {
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        let request = try makeRequest(path: "payment/create", method: "POST", body: jsonData)
        return try await sendRequest(request)
    }
    
    /// 9) Subscribe to a plan and return the created membership immediately.
    func subscribeAndReturnMembership(to planID: Int) async throws -> MembershipData {
        var request = try makeRequest(path: "subscribe", method: "POST")
        request.httpBody = try JSONEncoder().encode(["plan_id": planID])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 201 else {
            let str = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(str)
        }
        let wrapper = try jsonDecoder.decode(MembershipResponse.self, from: data)
        return wrapper.membership
    }
}
