//
//  PlanViewModel.swift
//  GymMembershipApp
//
//  Created by imac4 on 25/05/2025.
//

import Foundation
import Combine

@MainActor
class PlanViewModel: ObservableObject {
  @Published var plans: [Plan] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  func loadPlans() async {
    isLoading = true
    defer { isLoading = false }
    do {
      let fetched = try await withCheckedThrowingContinuation { cont in
        APIClient.shared.fetchPlans { result in
          cont.resume(with: result)
        }
      }
      plans = fetched
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func subscribe(to plan: Plan) async {
    isLoading = true
    defer { isLoading = false }
    do {
      try await withCheckedThrowingContinuation { cont in
        APIClient.shared.subscribe(to: plan.id) { result in
          cont.resume(with: result.map { _ in () })
        }
      }
      // You could post a Notification or update App state here
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
