//
//  PaymentHistoryView.swift
//  GymMembershipApp
//
//  Created by imac4 on 25/05/2025.
//

import SwiftUI

// MARK: - Payment History View
struct PaymentHistoryView: View {
    @StateObject private var vm = PaymentHistoryViewModel()

    var body: some View {
        NavigationView {
            Group {
                if vm.isLoading {
                    ProgressView("Loading payments…")
                } else if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if vm.payments.isEmpty {
                    Text("No payment history.")
                        .foregroundColor(.secondary)
                } else {
                    List(vm.payments) { payment in
                        PaymentRowView(payment: payment)
                    }
                    .listStyle(PlainListStyle())
                    .loadingErrorEmpty(
                        isLoading: vm.isLoading,
                        errorMessage: vm.errorMessage,
                        isEmpty: vm.payments.isEmpty,
                        emptyMessage: "No payment history."
                    )
                }
            }
            .navigationTitle("Payments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        vm.loadPayments()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task { vm.loadPayments() }
    }
}

struct PaymentHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentHistoryView()
    }
}
