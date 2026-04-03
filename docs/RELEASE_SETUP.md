# Release Setup Guide

This document explains how to configure the CI/CD release pipeline for **While You're Out** on both iOS (TestFlight) and Android (Play Store internal track).

The release workflow (`.github/workflows/release.yml`) is triggered automatically when a version tag matching `v*.*.*` is pushed to the repository (e.g. `v0.1.0`).

---

## Table of Contents

1. [Required GitHub Secrets](#required-github-secrets)
2. [iOS: App Store Connect Setup](#ios-app-store-connect-setup)
3. [Android: Google Play Console Setup](#android-google-play-console-setup)
4. [Android: Keystore Generation](#android-keystore-generation)
5. [First Release Checklist](#first-release-checklist)
6. [Tagging a Release](#tagging-a-release)
7. [Troubleshooting](#troubleshooting)

---

## Required GitHub Secrets

Navigate to **Settings → Secrets and variables → Actions** in the GitHub repository and add the following secrets.

### iOS Secrets

| Secret | How to obtain |
|---|---|
| `IOS_DISTRIBUTION_CERT_P12` | In Keychain Access, export your iOS Distribution certificate as a `.p12` file, then base64-encode it: `base64 -i cert.p12 \| pbcopy` |
| `IOS_DISTRIBUTION_CERT_PASSWORD` | The password you entered when exporting the `.p12` from Keychain Access |
| `APPSTORE_ISSUER_ID` | App Store Connect → Users and Access → Integrations → App Store Connect API → copy **Issuer ID** |
| `APPSTORE_API_KEY_ID` | App Store Connect → Users and Access → Integrations → App Store Connect API → copy the **Key ID** of your API key |
| `APPSTORE_API_PRIVATE_KEY` | Paste the full contents of the `.p8` file downloaded from App Store Connect when you created the API key (download is only available once) |

> **Note:** The `ExportOptions.plist` at `apps/mobile/ios/ExportOptions.plist` contains `teamID = REPLACE_WITH_TEAM_ID`. Before your first TestFlight upload, replace this placeholder with your actual Apple Developer **Team ID**, found at [developer.apple.com/account](https://developer.apple.com/account) under Membership Details.

### Android Secrets

| Secret | How to obtain |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | After [generating your keystore](#android-keystore-generation), run: `base64 -i whileyoureout.jks \| pbcopy` |
| `ANDROID_KEYSTORE_PASSWORD` | The `-storepass` value used when creating the keystore |
| `ANDROID_KEY_ALIAS` | The `-alias` value used when creating the keystore |
| `ANDROID_KEY_PASSWORD` | The `-keypass` value used when creating the keystore (often the same as the store password) |
| `PLAY_SERVICE_ACCOUNT_JSON` | Paste the full contents of the Google Cloud service account JSON file (see [Android setup](#android-google-play-console-setup)) |

### Shared Secrets

| Secret | How to obtain |
|---|---|
| `GOOGLE_MAPS_API_KEY` | Google Cloud Console → APIs & Services → Credentials → create an API key with Maps SDK for iOS and Maps SDK for Android enabled |

---

## iOS: App Store Connect Setup

### 1. Create an App Record

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com).
2. Go to **My Apps → +** and select **New App**.
3. Fill in:
   - **Platform**: iOS
   - **Name**: While You're Out
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: `com.yourcompany.whileyoureout` (must match the bundle ID registered in your Apple Developer account)
   - **SKU**: any unique string, e.g. `whileyoureout`

### 2. Create an App Store Connect API Key

1. Go to **Users and Access → Integrations → App Store Connect API**.
2. Click **+** to generate a new key.
3. Give it a name (e.g. `CI Release`) and set **Access** to **App Manager**.
4. Download the `.p8` file immediately — it can only be downloaded once.
5. Record the **Key ID** and **Issuer ID** for the GitHub secrets above.

### 3. App Information Required Before First Upload

- **Privacy Policy URL** — required before submission. Host a plain-text or HTML privacy policy (the app collects no data, so this can be minimal) at a stable URL.
- **Age Rating** — complete the age rating questionnaire (all "No" for this app → 4+).
- **Category** — suggest **Productivity** (primary) / **Utilities** (secondary).
- **App Description** — at least one screenshot per device class required before public release (TestFlight does not require screenshots).

### 4. IPA Filename Note

The CI workflow expects the IPA at:

```
apps/mobile/build/ios/ipa/whileyoureout.ipa
```

Flutter names the IPA after the Xcode scheme. If the build produces `Runner.ipa` instead, update the `app-path` in `.github/workflows/release.yml` accordingly, or rename the Xcode scheme to `whileyoureout` in Xcode under **Product → Scheme → Manage Schemes**.

---

## Android: Google Play Console Setup

### 1. Create an App Listing

1. Sign in to [Google Play Console](https://play.google.com/console).
2. Click **Create app** and fill in:
   - **App name**: While You're Out
   - **Default language**: English (United States)
   - **App or game**: App
   - **Free or paid**: Free
3. Accept the declarations and click **Create app**.

### 2. Complete Store Listing (Minimum for Internal Testing)

Internal track uploads do **not** require a full store listing, but you must complete:

- **App access**: all functionality available without special access
- **Content rating**: complete the questionnaire
- **Target audience**: adults (18+)

### 3. Create a Service Account for CI

1. In Google Play Console, go to **Setup → API access**.
2. Click **Link to a Google Cloud project** (or create a new one).
3. In Google Cloud Console, go to **IAM & Admin → Service Accounts → Create Service Account**.
   - Name: `play-store-release`
   - Role: no role needed at project level
4. Create and download a **JSON key** for the service account.
5. Back in Google Play Console, go to **Users and permissions → Invite new users**, paste the service account email, and grant the **Release to internal testing track** permission.
6. Paste the full JSON key contents into the `PLAY_SERVICE_ACCOUNT_JSON` GitHub secret.

---

## Android: Keystore Generation

The release signing keystore must be generated once and stored securely. **Never commit it to the repository.**

```sh
keytool -genkey -v \
  -keystore whileyoureout.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias whileyoureout \
  -storepass YOUR_STORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD \
  -dname "CN=While You're Out, OU=Mobile, O=Your Company, L=City, S=State, C=US"
```

After creating `whileyoureout.jks`:

1. Base64-encode it and add it as `ANDROID_KEYSTORE_BASE64` in GitHub Secrets.
2. Store a backup copy in a secure password manager or secret vault — **if this file and password are lost, you cannot update the app on the Play Store**.
3. The file is excluded from git via `*.jks` in `.gitignore` — confirm with `git status` that it is not staged.

The CI workflow decodes the keystore at build time:

```sh
echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode > apps/mobile/android/app/whileyoureout.jks
```

The Gradle signing config in `apps/mobile/android/app/build.gradle.kts` then reads the passwords from the `KEYSTORE_PASSWORD`, `KEY_ALIAS`, and `KEY_PASSWORD` environment variables injected by the workflow.

---

## First Release Checklist

### iOS

- [ ] Apple Developer account is active and `com.yourcompany.whileyoureout` App ID is registered
- [ ] Distribution certificate is in Keychain Access and exported as `.p12`
- [ ] App Store Connect API key created, `.p8` saved, Key ID and Issuer ID recorded
- [ ] App record created in App Store Connect
- [ ] `teamID` in `apps/mobile/ios/ExportOptions.plist` replaced with real Team ID
- [ ] All iOS GitHub Secrets added
- [ ] `flutter build ipa --no-codesign` succeeds locally from `apps/mobile/`

### Android

- [ ] Keystore generated and backed up securely
- [ ] App created in Google Play Console
- [ ] Service account created and granted release permission
- [ ] All Android GitHub Secrets added
- [ ] `flutter build appbundle --release` succeeds locally from `apps/mobile/` (uses debug signing)

### Both

- [ ] `GOOGLE_MAPS_API_KEY` secret added
- [ ] Privacy policy URL is live and added to both store listings

---

## Tagging a Release

Once all secrets are configured and the checklists above are complete, trigger a release by pushing a version tag:

```sh
git tag v0.1.0
git push origin v0.1.0
```

The `release.yml` workflow will:

1. Build and sign the iOS IPA → upload to TestFlight
2. Build and sign the Android AAB → upload to Play Store internal track
3. Create a GitHub Release with auto-generated notes from the tag

Monitor progress in the **Actions** tab of the GitHub repository.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `No such file or directory: whileyoureout.ipa` | Xcode scheme name mismatch | Check actual IPA filename in CI logs; update `app-path` in `release.yml` or rename Xcode scheme |
| `Keystore file not found` | `ANDROID_KEYSTORE_BASE64` secret missing or corrupt | Re-encode the keystore: `base64 -i whileyoureout.jks` and update the secret |
| `401 Unauthorized` on TestFlight upload | API key expired or wrong permissions | Regenerate key in App Store Connect with App Manager role |
| `403 Forbidden` on Play Store upload | Service account lacks release permission | Re-check Play Console → Users and permissions for the service account email |
| `Google Maps API key missing` warning | `GOOGLE_MAPS_API_KEY` secret not set | Add the secret and re-run the workflow |