# ChatX 💬

A premium, cross-platform real-time chat application built with **Flutter** and **Firebase**. 
ChatX was engineered with a focus on clean architecture, fluid animations, and a high-end iOS-inspired "Liquid Glass" design language.

---

## ✨ Key Features

- **Real-time Messaging**: Instantaneous chat sync powered by Firebase Cloud Firestore.
- **Secure Authentication**: End-to-end user registration and authentication via Firebase Auth.
- **Push Notifications**: Integrated Firebase Cloud Messaging (FCM) & local notifications for background and foreground alerts.
- **Premium UI/UX**: Custom-built Glassmorphism (Frosted Glass) components mimicking native iOS 16+ aesthetic (`sigma` blur, directional lighting, and volumetric shadows).
- **Responsive Design**: Flawlessly adapts across Mobile (Android/iOS) and Web/Desktop (split-pane layouts).
- **Dark/Light Mode**: Fully responsive thematic architecture out-of-the-box.
- **State Management**: Highly scalable, predictable state management using **Riverpod 2.0**.
- **Robust Routing**: Advanced navigation and deep-linking handled by `go_router`.

---

## 🛠 Tech Stack

- **Framework**: Flutter (Dart)
- **Backend**: Firebase (Auth, Firestore, Cloud Messaging)
- **State Management**: `flutter_riverpod`
- **Navigation**: `go_router`
- **Animations**: `flutter_animate`
- **CI/CD Pipeline**: Codemagic (YAML configured)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (`>= 3.0.0`)
- A Firebase Project (with Auth and Firestore enabled)

### Local Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/jainam-15/chatx.git
   cd chatx
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   Because this project uses Firebase, you must provide your own Firebase configuration files.
   - **Android**: Place your `google-services.json` inside `android/app/`
   - **iOS**: Place your `GoogleService-Info.plist` inside `ios/Runner/`
   - **Web**: Replace the `firebaseConfig` object in `web/index.html`

4. **Run the App**
   ```bash
   flutter run
   ```

---

## 📱 CI/CD & Simulator Testing (Appetize.io)

This repository includes a pre-configured `codemagic.yaml` pipeline specifically designed for automated iOS Simulator builds, making it perfect for recruiters to test via [Appetize.io](https://appetize.io/).

**To trigger a build:**
1. Ensure your `GoogleService-Info.plist` is committed to the repository (if testing a private fork).
2. Connect the repository to Codemagic.
3. The workflow will automatically install CocoaPods, build an `.app` bundle for the iOS Simulator (`x86_64` / `arm64`), and output a `ChatX_Simulator.zip` artifact.
4. Upload `ChatX_Simulator.zip` directly to Appetize.io to run the app in the browser.

---

## 🌐 Web Deployment (Vercel)

This repository is fully configured for instant deployment to Vercel.

**Vercel Setup:**
1. Import the repository into Vercel.
2. In the project settings, configure the following:
   - **Framework Preset**: `Other`
   - **Build Command**: `bash build.sh`
   - **Output Directory**: `build/web`
3. Click **Deploy**. Vercel will automatically download the Flutter SDK, build the web bundle, and host it globally. Routing is perfectly handled via the included `vercel.json`.

---

## 🏗 Architecture & Design Decisions

- **Provider Pattern**: Separated UI from business logic using Riverpod. Services (`AuthService`, `DatabaseService`, `NotificationService`) are injected as singletons.
- **Custom Theming Engine**: Built a centralized `BrandColors` and `AppTheme` engine to ensure UI consistency without scattering hardcoded colors.
- **Optimized UI Components**: Reusable widgets like `LiquidGlass` and `ChatXTextField` prevent code duplication and maintain the premium aesthetic globally.

---
*Developed as an interview demonstration of production-grade Flutter development.*
