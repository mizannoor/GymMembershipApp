//
//  DashboardView.swift
//  GymMembershipApp
//
//  Created by imac4 on 09/05/2025.
//

// DashboardView.swift

import SwiftUI

// MARK: - DashboardResponse
struct DashboardResponse: Codable {
  let status: String?
  let qr: String?
  let message: String?      // to catch “Unauthenticated.”
}

// MARK: - DashboardView
struct DashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var statusText: String = ""
    @State private var qrImage: Image?
    @State private var qrData: Data?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Loading…")
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    Text("Membership Status:")
                        .font(.headline)
                    Text(statusText)
                        .font(.title2)
                        .bold()

                    if let qr = qrImage {
                        qr
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding()
                    }

                    Spacer()

                    Button("Sign Out") {
                        authVM.signOut()
                    }
                    .padding()
                    .foregroundColor(.red)
                }
            }
            .padding()
            .navigationTitle("Dashboard")
            .onAppear(perform: loadDashboard)
        }
    }

    // MARK: - Load Dashboard Data
    private func loadDashboard() {
        isLoading = true
        errorMessage = nil

        APIClient.shared.fetchDashboard { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let dash):
                    statusText = (dash.status ?? "Unknown").capitalized
                    qrImage    = decodeBase64Image(from: dash.qr ?? "")
                case .failure(let err):
                    errorMessage = "Failed to load: \(err.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Decode Base64 string into SwiftUI Image
    private func decodeBase64Image(from base64: String) -> Image? {
        guard
          let data = Data(base64Encoded: base64),
          let uiImage = UIImage(data: data)    // will now succeed on PNG
        else {
          return nil
        }
        return Image(uiImage: uiImage)
    }

}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = AuthViewModel()
        DashboardView()
            .environmentObject(vm)
    }
}
