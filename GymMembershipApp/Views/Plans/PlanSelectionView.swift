//
//  PlanSelectionView.swift
//  GymMembershipApp
//
//  Created by imac4 on 25/05/2025.
//

import SwiftUI

struct PlanSelectionView: View {
    @StateObject private var vm = PlanViewModel()
    @State private var showPayment = false
    @State private var membershipId: Int?
    @State private var selectedPlan: Plan?
//    @State private var errorMessage: String?
//    @State private var isLoading = false

    var body: some View {
        NavigationView {
            contentView
                .navigationTitle("Choose a Plan")
                .toolbar { refreshToolbar }
                .task { await loadPlans() }
                .sheet(isPresented: $showPayment, onDismiss: clearSelection) {
                    sheetView
                }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if vm.isLoading {
            ProgressView("Loading plans…")
        } else if let error = vm.errorMessage {
            Text(error)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
        } else {
            planList
        }
    }

    private var planList: some View {
        List(vm.plans) { plan in
            Button {
                Task { await subscribeAndPay(plan: plan) }
            } label: {
                PlanRowView(plan: plan)
            }
        }
        // Apply loading / error / empty container:
        .loadingErrorEmpty(
            isLoading: vm.isLoading,
            errorMessage: vm.errorMessage,
            isEmpty: vm.plans.isEmpty,
            emptyMessage: "No plans available."
        )
        .listStyle(PlainListStyle())
    }

    private var refreshToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Task { await loadPlans() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
    }

    private var sheetView: some View {
        NavigationView {
            if let id = membershipId, let plan = selectedPlan {
                PaymentView(membershipId: id, amount: plan.price)
            } else {
                Text("Something went wrong.")
            }
        }
    }

    private func clearSelection() {
        membershipId = nil
        selectedPlan = nil
    }

    private func loadPlans() async {
        vm.isLoading = true
        defer { vm.isLoading = false }
        vm.errorMessage = nil
        vm.loadPlans()
    }

    private func subscribeAndPay(plan: Plan) async {
        vm.isLoading = true
        defer { vm.isLoading = false }
        vm.errorMessage = nil
        do {
            let membership = try await APIClient.shared.subscribeAndReturnMembership(to: plan.id)
            membershipId = membership.id
            selectedPlan = plan
            showPayment = true
        } catch {
            vm.errorMessage = error.localizedDescription
        }
    }
}

struct PlanSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        PlanSelectionView()
    }
}
