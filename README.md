# FitAI

AI-powered fitness coaching app scaffold for Android, iOS, and Web (PWA). Bold dark theme with neon accents. Monetization: subscriptions only with 15‑day trial. Analytics/Crash/Push: Firebase only. Backend: Supabase for auth/DB/storage.

## Tech + Architecture
- Flutter 3 (null-safety). Platforms: Android, iOS, Web (PWA manifest + service worker).
- Routing: go_router with URL-aware paths and tab scaffold.
- State: Riverpod + StateNotifier (providers ready; add notifiers per feature).
- Data: repository pattern (auth, user, activity, nutrition, workouts). Supabase client bootstrapped.
- Codegen: Freezed/json_serializable/retrofit wired via build_runner.
- Local cache: placeholder SharedPreferences wrapper (swap for Isar/Drift as needed).
- Analytics: Firebase Analytics + screen tracking observer; Crashlytics; FCM token retrieval.
- Subscriptions: RevenueCat (mobile), Stripe Checkout fallback (web placeholder) with 15‑day trial badge.
- Health: health package shell with permission flow. GPS: geolocator + start session stub.

## Flavors / Environments
- Android flavors: dev, stg, prod with bundle IDs:
  - com.fitai.app.dev / com.fitai.app.stg / com.fitai.app
  - App names via resValue; OAuth redirect scheme per flavor (fitai-dev, fitai-stg, fitai)
- iOS/Web: entrypoints select env: `lib/main.dart` (dev), `lib/main_stg.dart`, `lib/main_prod.dart`.
- Env files at project root: `.env.dev`, `.env.stg`, `.env.prod` with:
```
ENV=dev|stg|prod
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
REVENUECAT_API_KEY=...
STRIPE_PUBLISHABLE_KEY=...
STRIPE_PRICE_ID=...
MAPS_API_KEY=...
OAUTH_REDIRECT_URI=fitai[-dev|-stg]://auth-callback
WEB_REDIRECT_URL=https://.../auth/callback
```

## Running
- Web (PWA): `flutter run -d chrome -t lib/main.dart` (dev) or `lib/main_stg.dart` / `lib/main_prod.dart`.
- Android:
  - Dev: `flutter run -d android --flavor dev -t lib/main.dart`
  - Staging: `--flavor stg -t lib/main_stg.dart`
  - Prod: `--flavor prod -t lib/main_prod.dart`
- iOS: `flutter run -d ios -t lib/main.dart` (set Firebase GoogleService-Info.plist + URL types + schemes).

## What’s implemented
- Themed design system: Material 3 dark-first palette with neon gradients; metric tiles, gradient borders, progress ring, neon focus.
- Navigation skeleton: Onboarding flow, 5 tabs (Home, Train, Activity, Nutrition, Profile), loading/empty placeholders, hero/parallax section.
- Analytics service with typed events + go_router observer. Crashlytics init with safe fallbacks.
- Supabase bootstrap + Auth repository (Google/Apple OAuth), biometrics unlock helpers.
- Health + GPS scaffolding (permissions + live location). Nutrition stubs: quick add sheet, barcode scan page, meal photo assist with mock AI + Supabase Storage upload.
- Notifications: local notifications + reminders screen; FCM token retrieval.
- Subscriptions: RevenueCat SDK wiring on mobile; simple Paywall UI with 15‑day trial badge; Stripe web button placeholder.
- CI: GitHub Actions for analyze/test and web/android/ios builds.

## Required setup
1. Firebase
   - Add GoogleService-Info.plist (iOS), google-services.json (Android), and Web config in `web/index.html` or via `firebase_options.dart` (FlutterFire). Update `Firebase.initializeApp` accordingly.
   - Enable Analytics, Crashlytics, Cloud Messaging. On Android 13+ POST_NOTIFICATIONS permission is declared.
   - For Web push, keep `web/firebase-messaging-sw.js` present.
2. Supabase
   - Create projects for dev/stg/prod; fill `.env.*` vars. Add redirect URIs listed above.
3. RevenueCat
   - Create offerings with a 15‑day trial. Add `REVENUECAT_API_KEY` per env.
4. Stripe (Web only)
   - Configure Checkout for subscriptions with trial. Replace the placeholder action in `PaywallScreen` with real Checkout session creation.
5. Maps & Health
   - Put `MAPS_API_KEY` in Android flavors (already wired via resValue). iOS: add key in AppDelegate/Info.plist if needed. HealthKit/Google Fit entitlements/permissions per platform.
6. iOS flavors
   - Use shared schemes included: `FitAI-Dev`, `FitAI-Staging`, `FitAI-Prod`. These launch the appropriate Dart entrypoints.
   - Bundle IDs and display names per env are provided via xcconfig files in `ios/Flutter` (Dev/Stg/Prod). Select the scheme and ensure the corresponding xcconfig is applied if needed.

## Scripts
- Codegen: `flutter pub run build_runner build -d`
- Format/Analyze/Test: `flutter format . && flutter analyze && flutter test`

## Event taxonomy
app_open, onboarding_complete, workout_start, set_complete, session_complete, pr_unlocked, recommendation_view/accept, nutrition_quick_add, barcode_scan, photo_log_start/success, reminder_sent/tapped, streak_day_saved.

## Notes
- Offline cache currently uses SharedPreferences for simplicity; swap in Isar/Drift when ready (deps already added). Hydration-first patterns are scaffolded in Home.
- Web PWA manifest and theme color are configured; install prompt shows on supported browsers.
