// PrivacyPolicyView.swift
// GymMembershipApp
//
// Created by imac4 on 12/06/2025.

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.title)
                        .bold()
                        .padding(.bottom, 8)
                    Text("This app collects and processes your data only for the purpose of providing gym membership services. Your authentication is handled securely via Google Sign-In, and your data is never sold or shared with third parties except as required for app functionality. For more details, please contact support.")
                        .font(.body)
                    // Add more detailed policy as needed
                }
                .padding()
            }
            .navigationBarTitle("Privacy Policy", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView()
    }
}
