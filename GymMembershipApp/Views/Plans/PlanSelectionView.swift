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
    @State private var errorMessage: String?
    @State private var isLoading = false

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
        if isLoading {
            ProgressView("Loading plans…")
        } else if let error = errorMessage {
            Text(error)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
        } else {
            planList
        }
    }

    private var planList: some View {
        List(vm.plans) { plan in
            Button(action: {
                Task { await subscribeAndPay(plan: plan) }
            }) {
                planRow(plan)
            }
            .disabled(isLoading)
        }
    }

    private func planRow(_ plan: Plan) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(plan.name).font(.headline)
                Text(plan.subtitle).font(.subheadline)
            }
            Spacer()
            Text(plan.formattedPrice).bold()
        }
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
                PaymentView(membershipId: id/*, amount: plan.price*/)
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
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        await vm.loadPlans()
    }

    private func subscribeAndPay(plan: Plan) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            let membership = try await APIClient.shared.subscribeAndReturnMembership(to: plan.id)
            membershipId = membership.id
            selectedPlan = plan
            showPayment = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct PlanSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        PlanSelectionView()
    }
}
