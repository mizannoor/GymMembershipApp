//
//  PaymentHistoryView.swift
//  GymMembershipApp
//
//  Created by imac4 on 25/05/2025.
//

import SwiftUI

// MARK: - Payment Model
typealias PaymentID = Int

struct Payment: Codable, Identifiable {
    let id: PaymentID
    let amount: Double
    let status: String
    let created_at: String   // ISO8601 timestamp

    var formattedAmount: String {
        String(format: "$%.2f", amount)
    }
    var date: Date? {
        ISO8601DateFormatter().date(from: created_at)
    }
    var formattedDate: String {
        guard let date = date else { return "" }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}

// MARK: - Payment History ViewModel
@MainActor
class PaymentHistoryViewModel: ObservableObject {
    @Published var payments: [Payment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadPayments() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await withCheckedThrowingContinuation { cont in
                APIClient.shared.fetchPayments { result in
                    cont.resume(with: result)
                }
            }
            payments = fetched
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

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
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(payment.formattedAmount)
                                    .font(.headline)
                                Spacer()
                                Text(payment.status.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(payment.status == "success" ? .green : .orange)
                            }
                            if !payment.formattedDate.isEmpty {
                                Text(payment.formattedDate)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Payments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task { await vm.loadPayments() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task { await vm.loadPayments() }
    }
}

struct PaymentHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentHistoryView()
    }
}
