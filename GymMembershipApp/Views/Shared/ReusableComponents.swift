//
//  ReusableComponents.swift
//  GymMembershipApp
//
//  Created by imac4 on 31/05/2025.
//
//  This file contains a set of reusable SwiftUI subviews for common patterns:
//    - Loading + Error + Empty‐state containers
//    - Row views for Payments and Plans
//    - A dashboard status+QR view
//

import SwiftUI


// MARK: - 1) Loading / Error / Empty State Container

/// A container that handles three common states:
///   • isLoading: shows a ProgressView with an optional message
///   • errorMessage: shows a red, wrapped error text
///   • emptyMessage: shows a secondary‐colored "empty" message if content is empty
///
/// Usage Example:
/// ```swift
/// List(items) { item in
///   // your row
/// }
/// .listStyle(PlainListStyle())
/// .modifier(LoadingErrorEmptyModifier(
///     isLoading: vm.isLoading,
///     errorMessage: vm.errorMessage,
///     isEmpty: vm.items.isEmpty,
///     emptyMessage: "No items available."
/// ))
/// ```
struct LoadingErrorEmptyModifier: ViewModifier {
    let isLoading: Bool
    let errorMessage: String?
    let isEmpty: Bool
    let emptyMessage: String

    func body(content: Content) -> some View {
        Group {
            if isLoading {
                // 1. Loading state
                VStack {
                    ProgressView()
                    Text(emptyMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if let error = errorMessage {
                // 2. Error state
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if isEmpty {
                // 3. Empty state
                Text(emptyMessage)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                // 4. Content state
                content
            }
        }
    }
}

extension View {
    /// Applies a loading / error / empty placeholder around this view (typically a List or VStack).
    func loadingErrorEmpty(
        isLoading: Bool,
        errorMessage: String?,
        isEmpty: Bool,
        emptyMessage: String
    ) -> some View {
        self.modifier(
            LoadingErrorEmptyModifier(
                isLoading: isLoading,
                errorMessage: errorMessage,
                isEmpty: isEmpty,
                emptyMessage: emptyMessage
            )
        )
    }
}


// MARK: - 2) PaymentRowView

/// A single row representing one `Payment`.
/// Extracted from PaymentHistoryView’s VStack(HStack(Text, Spacer, Text), optional Date).
struct PaymentRowView: View {
    let payment: Payment

    var body: some View {
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
}


// MARK: - 3) PlanRowView

/// A single row representing one `Plan`.
/// Extracted from PlanSelectionView’s HStack(Text(name/subtitle), Spacer, Text(price)).
struct PlanRowView: View {
    let plan: Plan

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(plan.name)
                    .font(.headline)
                Text(plan.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(plan.formattedPrice)
                .bold()
        }
        .padding(.vertical, 8)
    }
}


// MARK: - 4) DashboardStatusView

/// Displays the membership status text and a QR image (if present).
/// Extracted from DashboardView’s VStack(Text + optional Image).
struct DashboardStatusView: View {
    let statusText: String
    let base64QRCode: String?

    var body: some View {
        VStack(spacing: 24) {
            Text("Membership Status:")
                .font(.headline)
            Text(statusText)
                .font(.title2)
                .bold()

            if let qrString = base64QRCode,
               let data = Data(base64Encoded: qrString),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()
            }
        }
        .padding()
    }
}


// MARK: - 5) Reusable Button Style for Primary Actions

/// A simple “prominent” button style you can apply to any button.
///
/// Usage:
/// ```swift
/// Button("Return to App") { … }
///     .buttonStyle(PrimaryActionButtonStyle())
/// ```
struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}


// MARK: - 6) Reusable Side Menu Row

/// A single row in the side menu: icon + label, tappable to change `selection`.
/// Extracted from SideMenu’s ForEach(MenuOption.allCases) { … }.
struct SideMenuRow: View {
    let option: MenuOption
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: option.iconName)
                .frame(width: 24, height: 24)
            Text(option.rawValue)
                .font(.headline)
        }
        .padding(.vertical, 8)
        .onTapGesture { action() }
    }
}


/// A simple “toast” banner that slides in at the top and then fades away.
struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline).bold()
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.8))
            )
            .shadow(radius: 4)
            .padding(.horizontal, 40)
    }
}
