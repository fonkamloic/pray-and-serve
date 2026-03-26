# App Store & Play Store Publishing Checklist

## 1. App Identity & Branding
- [x] Fix Android display name in AndroidManifest.xml
- [x] Fix iOS display names (CFBundleDisplayName + CFBundleName) in Info.plist
- [x] Generate custom app icon (gold cross on dark background)
- [x] Generate platform-specific icons via flutter_launcher_icons
- [x] Generate splash screens via flutter_native_splash

## 2. Android Signing
- [x] Generate a production upload keystore (`android/app/upload-keystore.jks`)
- [x] Create `android/key.properties` with keystore credentials (already gitignored)
- [x] Configure release signing in `android/app/build.gradle.kts`
- [x] Enable ProGuard/R8 shrinking for release builds
- [x] Verified: `flutter build appbundle --release` produces signed AAB (44.6MB)

## 3. iOS Signing
- [x] Enroll in Apple Developer Program (Team ID: KF76DSB8GZ)
- [x] Set Development Team ID in Xcode project settings (auto-signing configured)
- [x] Configure distribution provisioning profiles (auto-managed)
- [x] Verify bundle ID `com.flutterplaza.prayAndServe` is registered
- [x] Verified: `flutter build ipa --release` produces IPA (21.6MB)

## 4. Store Listing Assets
- [x] App icon: 1024x1024 PNG (`assets/app_icon.png`)
- [ ] Screenshots: iPhone 6.7" and 6.5" (iOS); phone + 7" and 10" tablet (Android)
- [x] Short description — see `assets/store_listing.txt`
- [x] Full description — see `assets/store_listing.txt`
- [x] Feature graphic 1024x500 (`assets/feature_graphic.png`)
- [x] App category: Lifestyle
- [x] Privacy policy URL: `https://fonkamloic.github.io/pray-and-serve/privacy.html`
- [x] Support URL: `https://www.fonkamloic.com/#contact`

## 5. Privacy & Compliance
- [x] Write privacy policy (`assets/privacy_policy.html`)
- [x] Privacy policy ready for GitHub Pages hosting (`docs/privacy.html`)
- [x] Support page ready for GitHub Pages hosting (`docs/support.html`)
- [x] Landing page ready for GitHub Pages hosting (`docs/index.html`)
- [ ] Enable GitHub Pages (Settings > Pages > Source: /docs from main branch)
- [ ] Complete Apple's App Privacy questionnaire (answer: no data collected)
- [ ] Complete Google's Data Safety form (answer: no data collected or shared)
- [ ] Complete age/content rating questionnaire (both stores)
- [x] Bundle google_fonts locally (fonts in `google_fonts/`, runtime fetching disabled in main.dart)

## 6. Build Configuration
- [x] Set final version number in pubspec.yaml (1.0.0+1 — appropriate for initial release)
- [x] Verify min SDK versions are appropriate (Android: Flutter default; Dart SDK ^3.11.0)
- [x] Remove debug prints and dev-only code (none found — codebase is clean)
- [x] `flutter build appbundle --release` — success (44.6MB AAB)
- [x] `flutter build ipa --release` — success (21.6MB IPA)

## 7. Testing
- [x] 466 automated tests passing (unit, widget, layout, integration)
- [x] Layout tested across 8 device sizes (280px–1366px) including foldable, landscape, tablet
- [x] Bottom sheet modals tested on narrow screens (Galaxy Fold 280px)
- [x] Landscape orientation tested (iPhone SE, iPhone 14, iPad Mini)
- [x] `flutter analyze` — 0 errors, 0 warnings (10 info-level lints only)
- [ ] Test on multiple real devices (small phone, large phone, tablet)
- [ ] Verify data persistence across app restarts on real device

## 8. Play Store Submission
- [ ] Create Google Play Developer account ($25 one-time fee)
- [ ] Create app in Google Play Console
- [ ] Upload AAB to internal/closed testing first
- [ ] Complete store listing, content rating, pricing & distribution
- [ ] Complete 20 testers requirement for closed testing (14 days) before production access
- [ ] Submit for review

## 9. App Store Submission
- [ ] Create app record in App Store Connect
- [ ] Upload IPA via Transporter app or `xcrun altool`
- [ ] Fill out App Information, Pricing, and Availability
- [ ] Submit screenshots for all required device sizes
- [ ] Submit for App Review

## 10. Post-Launch
- [ ] Add crash reporting (Firebase Crashlytics or Sentry)
- [ ] Plan for user feedback and update cycle
- [ ] Monitor store reviews
