//
//  GymMembershipAppApp.swift
//  GymMembershipApp
//
//  Created by imac4 on 09/05/2025.
//

import GoogleSignIn
import SwiftUI
//import SquareInAppPaymentsSDK
import FirebaseCore
import FirebaseAnalytics

@main
struct GymMembershipApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authVM = AuthViewModel()
    
    init() {
        // Replace with your Square Application ID from the Developer Dashboard
//        SQIPInAppPaymentsSDK.squareApplicationID = "sandbox-sq0idb-70FC7t_kyY8WOqC-9uD5SQ"
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM).preferredColorScheme(.dark) // Force dark mode if desired
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure() // 🔥 Initialize Firebase here
        Analytics.setAnalyticsCollectionEnabled(true)
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey:Any] = [:]
    ) -> Bool {
        guard url.scheme == Constants.callbackURLScheme,
              url.host   == "payment-complete"
        else {
            return false
        }

        // Notify the app that payment just finished
        NotificationCenter.default.post(name: .paymentDidComplete, object: nil)

        // Let GoogleSignIn also handle callback
        return GIDSignIn.sharedInstance.handle(url)
    }
}
