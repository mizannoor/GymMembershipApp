//
//  PlanSelectionView.swift
//  GymMembershipApp
//
//  Created by imac4 on 25/05/2025.
//

import SwiftUI
import FirebaseAnalytics

struct PlanSelectionView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var vm = PlanViewModel()
    @State private var showPayment = false
    @State private var membershipId: Int?
    @State private var selectedPlan: Plan?
    
    var body: some View {
        NavigationView {
            contentView
                .navigationTitle("Choose a Plan")
                .toolbar { refreshToolbar }
                .onAppear {
                    Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                        AnalyticsParameterScreenName: "PlanSelectionView",
                        AnalyticsParameterScreenClass: "PlanSelectionView"
                    ])

                    // Only load plans if we haven't already fetched them
                    if vm.plans.isEmpty {
                        if(vm.searchText.isEmpty) { vm.loadPlans() }
                    }
                }
                .sheet(isPresented: $showPayment, onDismiss: clearSelection) {
                    sheetView
                }
                .onReceive(NotificationCenter.default.publisher(for: .paymentDidComplete)) { _ in
                    // First, the sheet (PaymentView) will already have dismissed itself.
                    // Now dismiss PlanSelectionView from the Navigation stack, returning to Dashboard.
                    presentationMode.wrappedValue.dismiss()
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
                .padding()
        } else {
            planList
        }
    }
    
    private var planList: some View {
        VStack(spacing: 0) {
            // Search bar pinned above the list
            TextField("Search plans…", text: $vm.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .padding(.top, 8)
            
            List(vm.plans) { plan in
                Button {
                    Task { await subscribeAndPay(plan: plan) }
                } label: {
                    PlanRowView(plan: plan)
                }
            }
            .loadingErrorEmpty(
                isLoading: vm.isLoading,
                errorMessage: vm.errorMessage,
                isEmpty: vm.plans.isEmpty,
                emptyMessage: vm.searchText.isEmpty
                    ? "No plans available."
                    : "No plans match your search."
            )
            .listStyle(PlainListStyle())
        }
    }
    
    private var refreshToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                vm.loadPlans()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
    }
    
    private var sheetView: some View {
        NavigationView {
            if let id = membershipId, let plan = selectedPlan {
                // Pass the plan.price if your PaymentView needs it
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
    
    private func subscribeAndPay(plan: Plan) async {
        vm.isLoading = true
        defer { vm.isLoading = false }
        vm.errorMessage = nil
        
        Analytics.logEvent("subscription_initiated", parameters: [
            "plan_id": plan.id,
            "plan_name": plan.name
        ])
        
        do {
            // OPTION 1: If your /subscribe returns JSON { "membership": { … } }
            // let membership = try await APIClient.shared.subscribeAndReturnMembership(to: plan.id)
            // membershipId = membership.id
            // selectedPlan = plan
            // showPayment = true
            
            // OPTION 2: If your /subscribe returns 201 Created with NO BODY, use this:
            let membership = try await APIClient.shared.subscribeAndReturnMembership(to: plan.id)
            // (subscribeAndReturnMembership would do the two-step: POST then GET current membership)
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
