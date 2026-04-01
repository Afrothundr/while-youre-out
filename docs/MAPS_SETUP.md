# Google Maps & Places API Setup

## Google Cloud Console — one-time setup

1. Go to https://console.cloud.google.com/
2. Create or select a project.
3. Enable these APIs on a single API key:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
4. Under **API restrictions**, restrict the key to only those three APIs.
5. Under **Application restrictions**:
   - For Android: restrict to the app's SHA-1 fingerprint and package name (`com.yourcompany.whileyoureout`)
   - For iOS: restrict to the bundle ID (`com.yourcompany.whileyoureout`)

   > Use separate keys per platform in production for stricter security.

---

## Android local setup

Add your key to `apps/mobile/android/local.properties` (this file is gitignored):

```
GOOGLE_MAPS_API_KEY=YOUR_KEY_HERE
```

The key is read by `build.gradle.kts` and injected into `AndroidManifest.xml` as a manifest
placeholder at build time. If `local.properties` is absent (e.g. on a clean CI machine), the
build falls back to the `GOOGLE_MAPS_API_KEY` environment variable.

---

## iOS local setup

Edit `apps/mobile/ios/Flutter/Debug.xcconfig` and replace the placeholder value:

```
GOOGLE_MAPS_API_KEY = YOUR_KEY_HERE
```

Do the same in `apps/mobile/ios/Flutter/Release.xcconfig`.

The XCConfig build setting flows into `Info.plist` via `$(GOOGLE_MAPS_API_KEY)`, and
`AppDelegate.swift` reads it from the bundle at launch to initialise the Google Maps SDK
(`GMSServices.provideAPIKey(_:)`).

> **Do not commit your real key.** The placeholder `YOUR_KEY_HERE` is what should appear
> in version control. Replace it locally and never stage the change.

---

## Running the app locally

Always pass the key as a `--dart-define` so the Places API (called from Dart code) can
access it at runtime:

```bash
cd apps/mobile
flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY_HERE
```

Or export it as an environment variable and use the melos script (which reads
`$GOOGLE_MAPS_API_KEY` automatically):

```bash
export GOOGLE_MAPS_API_KEY=YOUR_KEY_HERE
melos build:ios
melos build:android
```

---

## CI / GitHub Actions

Add `GOOGLE_MAPS_API_KEY` as a repository secret in GitHub:

> **Settings → Secrets and variables → Actions → New repository secret**

The CI workflow (`ci.yml`) already picks it up:

- The `build-ios` and `build-android` jobs set the secret as an environment variable, and
  the melos build scripts forward it to Flutter via `--dart-define=GOOGLE_MAPS_API_KEY=`.
- The Android Gradle build reads the same environment variable to resolve the
  `${GOOGLE_MAPS_API_KEY}` manifest placeholder.

No further changes to CI are needed once the secret is added.

---

## Verifying the Android key resolved correctly

After a debug build, inspect the merged manifest:

```bash
cat apps/mobile/android/app/build/intermediates/merged_manifests/debug/AndroidManifest.xml \
  | grep -A2 "geo.API_KEY"
```

The `android:value` attribute should contain your actual key, **not** the literal string
`${GOOGLE_MAPS_API_KEY}` or an empty string.

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Blank/grey map tiles on Android | `GOOGLE_MAPS_API_KEY` not resolved in manifest — check `local.properties` or the CI env var |
| `GoogleMaps not initialized` crash on iOS | `GMSServices.provideAPIKey` not called before plugin registration — check `AppDelegate.swift` |
| Places API returns 403 | Key does not have **Places API** enabled in Cloud Console |
| Map works locally but not in CI | Secret not added to GitHub Actions repository secrets |