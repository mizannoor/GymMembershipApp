# UTeM : MMSD 5223 - Native Mobile Development II



# 📱 GymMembershipApp (iOS - SwiftUI)

This is the **iOS mobile frontend** for the Gym Membership System. Built using SwiftUI and MVVM architecture, the app integrates with a Laravel backend to allow users to register via Google, subscribe to gym plans, view membership status, and scan QR codes. Square is used for payment processing.

---
## ✅ Features

- 🔐 **Gmail Sign-In** (OAuth 2.0)
- 📲 **JWT-based Authentication**
- 🏋️‍♂️ View and manage **Membership Plans**
- 📆 Subscribe to **1, 3, 6, 12-month packages**
- 📦 Display **QR Code** linked to active membership
- 💳 Handle **Square Payment Integration**
- 🔍 **Search functionality** for plans or user info
- 🌙 **Dark Mode** UI with SwiftUI theming



## 📁 Project Structure

```bash
.
├── GymMembershipApp
│   ├── Assets.xcassets
│   │   ├── AccentColor.colorset
│   │   │   └── Contents.json
│   │   ├── AppIcon.appiconset
│   │   │   └── Contents.json
│   │   ├── AppLogo.imageset
│   │   │   ├── AppLogo.jpeg
│   │   │   └── Contents.json
│   │   ├── google_logo.imageset
│   │   │   ├── google_logo.png
│   │   │   └── Contents.json
│   │   └── Contents.json
│   ├── GoogleService-Info.plist
│   ├── Info.plist
│   ├── Models
│   │   ├── Entities.swift
│   │   └── ViewModel.swift
│   ├── Preview Content
│   │   └── Preview Assets.xcassets
│   │       └── Contents.json
│   ├── Services
│   │   └── Services.swift
│   ├── Utilities
│   │   └── Constants.swift
│   └── Views
│       ├── Account
│       │   └── ProfileView.swift
│       ├── Authentication
│       │   ├── GoogleButtons.swift
│       │   └── SignInView.swift
│       ├── Dashboard
│       │   └── DashboardView.swift
│       ├── Payments
│       │   ├── PaymentHistoryView.swift
│       │   └── PaymentView.swift
│       ├── Plans
│       │   └── PlanSelectionView.swift
│       └── Shared
│           ├── ContentView.swift
│           ├── GymMembershipAppApp.swift
│           ├── MenuOption.swift
│           ├── PrivacyPolicyView.swift
│           ├── ReusableComponents.swift
│           └── SideMenu.swift
├── GymMembershipApp.xcodeproj
│   ├── project.pbxproj
│   ├── project.xcworkspace
│   │   └── contents.xcworkspacedata
│   ├── xcshareddata
│   │   └── xcschemes
│   │       └── GymMembershipApp.xcscheme
│   └── xcuserdata
│       └── imac4.xcuserdatad
│           ├── xcdebugger
│           └── xcschemes
├── GymMembershipAppTests
│   └── GymMembershipAppTests.swift
├── GymMembershipAppUITests
│   ├── GymMembershipAppUITests.swift
│   └── GymMembershipAppUITestsLaunchTests.swift
└── README.md
```



## 🧱 Architecture

The app follows **MVVM (Model-View-ViewModel)** with:

- `ViewModel` using `@Published` and `@StateObject`
- **Networking** layer using `URLSession` for API calls
- **Secure token storage** via `KeychainWrapper` or `UserDefaults`
- Reusable `View` components for QR and payment status

---

```mermaid
---
config:
  layout: fixed
---
flowchart TD
 subgraph Frontend["Frontend"]
        A["User (iOS App - SwiftUI)"]
  end
 subgraph Backend["Backend"]
        C["Laravel Backend API"]
        D["MySQL Database"]
        F["QR Generator Library"]
  end
 subgraph subGraph2["External Services"]
        B["Google OAuth 2.0"]
        E["Square API"]
  end
    A -- Login via Google --> B
    B -- Returns ID Token --> C
    C -- Issues JWT Token --> A
    A -- Uses JWT for Auth --> C
    A -- Fetch Membership Plans --> C
    A -- Subscribe to Plan --> C
    C -- Store/Query Data --> D
    C -- Generate Checkout Link --> E
    A -- Redirects to Payment URL --> E
    E -- Sends Payment Callback --> C
    C -- Updates Membership & Payment Status --> D
    C -- Generates QR Code --> F
    C -- Sends Base64 QR to App --> A

```

---

## 🔑 Authentication

- Uses **Google Sign-In** (via `SignInWithGoogle` package or custom OAuth flow)
- On success:
  - Backend issues a **JWT**
  - JWT is saved in app storage
  - Subsequent requests attach `Authorization: Bearer TOKEN`

---

## 🌐 API Integration

Backend base URL (example):

```swift
let baseURL = "https://your-ngrok-url/api"
````

Sample endpoints:

| Action              | Endpoint                | Method |
| ------------------- | ----------------------- | ------ |
| Google Sign-In      | `/auth/google/redirect` | GET    |
| Fetch membership    | `/memberships`          | GET    |
| List plans          | `/membership-plans`     | GET    |
| Subscribe to a plan | `/subscribe`            | POST   |
| Process payment     | `/payments`             | POST   |

---

## 💳 Payment with Square

* Payment request sent via API
* Payment screen in SwiftUI handles response
* Result stored and displayed with confirmation

---

## 🖼️ Screenshots

> *You can include actual images here once available*

* ✅ Gmail Login
* ✅ Membership Dashboard
* ✅ QR Code Display
* ✅ Plan Selection & Payment
* ✅ Email Notification Preview

---

## 🛠 Requirements

* Xcode 15+
* iOS 15+
* Swift 5+
* Enable **Sign-In with Google** in your Firebase or Google Cloud Console
* Connected Laravel backend (see: [gym-backend](https://github.com/mizannoor/gym-backend))

---

## 📦 Dependencies

* SwiftUI
* Combine
* URLSession
* Square payment (through backend)
* Google Sign-In (OAuth flow)
* QR Code rendering (`CoreImage.CIFilter.qrCodeGenerator`)

---

## 🔒 Security

* JWT stored in secure container
* HTTPS enforced on API calls
* Token refresh logic can be added

---

## 📥 Installation & Setup

1. Clone the repository

```bash
git clone https://github.com/mizannoor/GymMembershipApp.git
```

2. Open `GymMembershipApp.xcodeproj` in Xcode

3. Update backend URL and Google client ID in `Info.plist` or constants file

4. Build and run on iOS Simulator or device

---

## 📱 Backend

Backend is built using **Laravel** and connects via REST API. See [gym-backend Laravel Repository](https://github.com/mizannoor/gym-backend).

---

---

## 🪪 License

This project is open-source and available under the [MIT license](LICENSE).


