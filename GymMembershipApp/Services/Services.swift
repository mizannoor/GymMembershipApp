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

    func save(_ data: Data, service: String, account: String) {
        // Existing implementation…
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account
        ]
        SecItemDelete(query as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account,
            kSecValueData as String   : data
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

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
// Callers expect { "membership": { … } } or { "membership": null }
fileprivate struct CurrentMembershipResponse: Decodable {
    let membership: MembershipData?
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
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Attach JSON headers
        request.setValue(Constants.applicationJson, forHTTPHeaderField: Constants.acceptHeader)
        request.setValue(Constants.applicationJson, forHTTPHeaderField: Constants.contentTypeHeader)
        
        // Attach Bearer token if available
        if let data = KeychainHelper.standard.read(
            service: Constants.keychainService,
            account: Constants.keychainAccount
        ), let token = String(data: data, encoding: .utf8), !token.isEmpty {
            request.setValue(
                "\(Constants.bearerTokenPrefix)\(token)",
                forHTTPHeaderField: Constants.authorizationHeader
            )
        }
        print("🔷 makeRequest:", method, url)
        request.httpBody = body
        return request
    }
    
    /// Sends a URLRequest, checks for HTTP 2xx status code, and decodes JSON into `T: Decodable`.
    private func sendRequest<T: Decodable>(
      _ request: URLRequest
    ) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // DEBUG: Print HTTPURLResponse or fallback
          if let httpResp = response as? HTTPURLResponse {
            print("🔷 HTTP status code:", httpResp.statusCode)
          } else {
            print("🔷 Response was not HTTPURLResponse:", response)
          }

          // DEBUG: Print raw response body
          if let text = String(data: data, encoding: .utf8) {
            print("🔸 Raw response body:", text)
          }
        
        guard let httpResp = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(httpResp.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? "No body"
            throw APIError.serverError("Status \(httpResp.statusCode): \(bodyString)")
        }
        
        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    // MARK: - Public API Methods (async/await)
    
    /// 1) Exchange Google ID token for backend JWT.
    ///    Note: This remains callback‐based because GoogleSignIn SDK uses a closure.
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
    
    /// 2) Fetch current user’s dashboard data (status, QR, start/end dates).
    func fetchDashboard() async throws -> DashboardResponse {
        do {
            let request = try makeRequest(path: "dashboard")
            return try await sendRequest(request)
        } catch {
            // If the server returned {"message":"Unauthenticated."}, force a logout:
            let msg = (error as? APIError)?.localizedDescription ?? error.localizedDescription
            if msg.contains("Unauthenticated") {
                // Post to notify the app that the JWT is invalid
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .unauthenticated, object: nil)
                }
            }
            // Re‐throw so that view models can still capture the error if needed
            throw error
        }
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
    
    /// 5) Subscribe to a plan *and* return the new membership‐object immediately.
    func subscribeAndReturnMembership(to planID: Int) async throws -> MembershipData {
        // 1) Encode body
        let bodyData = try JSONEncoder().encode(["plan_id": planID])

        // 2) Build the request (POST /subscribe)
        let subscribeRequest = try makeRequest(path: "subscribe", method: "POST", body: bodyData)

        // 3) Fire the request
        let (_, response) = try await URLSession.shared.data(for: subscribeRequest)

        // 4) Ensure it was 201 Created
        guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 201 else {
            throw APIError.invalidResponse
        }

        // 5) Now call “GET /membership/current” and decode the JSON { "membership": { … } }
        let currentRequest = try makeRequest(path: "membership/current")
        let wrapper: CurrentMembershipResponse = try await sendRequest(currentRequest)

        // 6) Unwrap and return
        if let membership = wrapper.membership {
            return membership
        } else {
            // If backend returned { "membership": null }, treat as error or return a default
            throw APIError.serverError("No membership data returned")
        }
    }

    
    /// 6) Create a checkout link for a membership; returns `CheckoutLinkResponse`.
    func createCheckoutLink(for membershipId: Int) async throws -> CheckoutLinkResponse {
        let bodyData = try JSONEncoder().encode(["membership_id": membershipId])
        let request = try makeRequest(path: "payment/checkout-link", method: "POST", body: bodyData)
        return try await sendRequest(request)
    }

    /// 7) Check the status of a payment. Returns a string like "success" or "pending".
    func checkPaymentStatus(paymentId: Int) async throws -> String {
        let request = try makeRequest(path: "payment/\(paymentId)/status")
        let wrapper: [String: String] = try await sendRequest(request)
        guard let status = wrapper["status"] else {
            throw APIError.invalidResponse
        }
        return status
    }
    
    /// 8) Fetch all past payments.
    func fetchPayments() async throws -> [Payment] {
        let request = try makeRequest(path: "payments")
        return try await sendRequest(request)
    }
    
    /// 9) Create a new payment. Returns `CreatePaymentResponse`.
    func createPayment(body: [String: Any]) async throws -> CreatePaymentResponse {
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        let request = try makeRequest(path: "payment/create", method: "POST", body: jsonData)
        return try await sendRequest(request)
    }
    
    /// 10) **Cancel an active membership.**
    ///     Replace `"subscription/cancel"` with whatever your backend expects.
    func cancelSubscription() async throws {
        // If backend requires a body, add it here; otherwise, this stub assumes no JSON body:
        let request = try makeRequest(path: "subscription/cancel", method: "POST")
        let _: EmptyResponse = try await sendRequest(request)
    }
    
    /// 11) Delete the authenticated user (and all related data).
    func deleteAccount() async throws {
        let request = try makeRequest(path: "user", method: "DELETE")
        // We expect no payload on success, so decode into EmptyResponse
        let _: EmptyResponse = try await sendRequest(request)
    }
    
    /// 12) Fetch the authenticated user’s profile (id, name, email).
    func fetchProfile() async throws -> User {
        // Builds GET /api/user with Authorization header
        let request = try makeRequest(path: "user")
        return try await sendRequest(request)
    }
}
