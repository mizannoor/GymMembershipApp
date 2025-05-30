//
//  APIClient.swift
//  GymMembershipApp
//
//  Created by imac4 on 09/05/2025.
//

import Foundation

struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

final class APIClient {
    static let shared = APIClient()
    private let baseURL: URL

    private init() {
        let urlString =
            Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as! String
        self.baseURL = URL(string: urlString)!
    }

    func authenticateWithGoogle(
        idToken: String,
        completion: @escaping (Result<AuthResponse, Error>) -> Void
    ) {
        let url = baseURL
            .appendingPathComponent("auth")
            .appendingPathComponent("google")
            .appendingPathComponent("token")
        // POST {"id_token":"…"} and decode as AuthResponse

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["id_token": idToken]
        req.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: req) { data, _, err in
          if let err = err { return completion(.failure(err)) }
          guard let data = data else { return }

          // ——— ADD THIS BLOCK ———
          if let s = String(data: data, encoding: .utf8) {
            print("👉 raw response: \(s)")
          }
          // ———————————————

          do {
            let auth = try JSONDecoder().decode(AuthResponse.self, from: data)
            completion(.success(auth))
          } catch {
            completion(.failure(error))
          }
        }.resume()

    }

    func authorizedRequest(
        path: String, method: String = "GET", body: Data? = nil
    ) -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        
        // add this line
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 🛠️ Attach JWT from Keychain
        if let data = KeychainHelper.standard.read(service: "gym", account: "accessToken"),
           let token = String(data: data, encoding: .utf8),
           !token.isEmpty {
          req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
          print("⚠️ No token in Keychain")
        }
        req.httpBody = body
        return req
    }

    // Example: Fetch dashboard
    func fetchDashboard(completion: @escaping (Result<DashboardResponse, Error>) -> Void) {
        let req = authorizedRequest(path: "dashboard")
        print("🔗 Fetching dashboard with headers:", req.allHTTPHeaderFields ?? [:])
        URLSession.shared.dataTask(with: req) { data, _, err in
          if let err = err { return completion(.failure(err)) }
          guard let data = data else { return }
          if let s = String(data: data, encoding: .utf8) {
            print("👉 raw dashboard response:", s)
          }
          do {
            let dash = try JSONDecoder().decode(DashboardResponse.self, from: data)
            completion(.success(dash))
          } catch {
            completion(.failure(error))
          }
        }.resume()
    }
    

    // Fetch available plans
    func fetchPlans(completion: @escaping (Result<[Plan], Error>) -> Void) {
      let req = authorizedRequest(path: "plans")
      URLSession.shared.dataTask(with: req) { data, _, err in
        if let err = err { return completion(.failure(err)) }
        guard let data = data else { return }
        do {
            if let s = String(data: data, encoding: .utf8) {
              print("❓ raw plans response: \(s)")
            }

            let wrapper = try JSONDecoder().decode([String: [Plan]].self, from: data)
            completion(.success(wrapper["plans"] ?? []))
        } catch {
            completion(.failure(error))
        }
      }.resume()
    }

    // Subscribe to a plan
    func subscribe(to planID: Int, completion: @escaping (Result<Void, Error>) -> Void) {
//      let url = baseURL.appendingPathComponent("subscribe")
      var req = authorizedRequest(path: "subscribe", method: "POST")
      let body = ["plan_id": planID]
      req.httpBody = try? JSONEncoder().encode(body)
      URLSession.shared.dataTask(with: req) { _, resp, err in
        if let err = err { return completion(.failure(err)) }
        guard let http = resp as? HTTPURLResponse, http.statusCode == 201 else {
          return completion(.failure(NSError(
            domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Subscription failed"]
          )))
        }
        completion(.success(()))
      }.resume()
    }
    
    // Fetch payment history
    func fetchPayments(completion: @escaping (Result<[Payment], Error>) -> Void) {
      let req = authorizedRequest(path: "payments")
      URLSession.shared.dataTask(with: req) { data, _, err in
        if let err = err { return completion(.failure(err)) }
        guard let data = data else { return }
        do {
            if let s = String(data: data, encoding: .utf8) {
              print("❓ raw payments response: \(s)")
            }
            let payments = try JSONDecoder().decode([Payment].self, from: data)
            completion(.success(payments))
        } catch {
            completion(.failure(error))
        }
      }.resume()
    }


    func createPayment(body: [String: Any], completion: @escaping (Result<CreatePaymentResponse, Error>) -> Void) {
        var req = authorizedRequest(path: "payment/create", method: "POST")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: req) { data, _, err in
          if let err = err {
            return completion(.failure(err))
          }
          guard let data = data else {
            let noDataErr = NSError(
              domain: "",
              code: 0,
              userInfo: [NSLocalizedDescriptionKey: "No data in response"]
            )
            return completion(.failure(noDataErr))
          }
          do {
            let resp = try JSONDecoder().decode(CreatePaymentResponse.self, from: data)
            completion(.success(resp))
          } catch {
            completion(.failure(error))
          }
        }.resume()
      }

}

extension APIClient {
  /// Subscribe to a plan and return the created membership
  func subscribeAndReturnMembership(to planID: Int) async throws -> MembershipData {
    var req = authorizedRequest(path: "subscribe", method: "POST")
    req.httpBody = try JSONEncoder().encode(["plan_id": planID])
    let (data, resp) = try await URLSession.shared.data(for: req)
    guard let status = (resp as? HTTPURLResponse)?.statusCode, status == 201 else {
      let str = String(data: data, encoding: .utf8) ?? "Unknown error"
      throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: str])
    }
    let wrapper = try JSONDecoder().decode(MembershipResponse.self, from: data)
    return wrapper.membership
  }
}

extension APIClient {
  /// One‐step: create the pending payment record & get Square checkout URL
    func createCheckoutLink(for membershipId: Int) async throws -> CheckoutLinkResponse {
        var req = try authorizedRequest(path: "payment/checkout-link", method: "POST")
        let body = ["membership_id": membershipId]
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: req)

        if let str = String(data: data, encoding: .utf8) {
            print("🔍 Raw checkout-link response:", str)
        }

        do {
            return try JSONDecoder().decode(CheckoutLinkResponse.self, from: data)
        } catch {
            print("❌ Decoding error:", error)
            throw error
        }
    }

}

extension APIClient {
    func checkPaymentStatus(paymentId: Int) async throws -> String {
        let req = authorizedRequest(path: "payment/status/\(paymentId)")
        
        let (data, response) = try await URLSession.shared.data(for: req)

        if let s = String(data: data, encoding: .utf8) {
            print("📦 raw status response: \(s)")
        }

        let result = try JSONDecoder().decode([String: String].self, from: data)
        guard let status = result["status"] else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing payment status"])
        }
        return status
    }
}
