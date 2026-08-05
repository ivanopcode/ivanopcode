# FirebaseCore + FirebaseCrashlytics XCFramework builder

`build-firebase-xcframeworks.sh` builds static XCFrameworks from a selected
`firebase/firebase-ios-sdk` tag by invoking Firebase's own
`ReleaseTooling/zip-builder`.

The selected Git tag must be a published CocoaPods release. The script uses
the checkout's release tooling and resolves the matching source podspecs by
version. This avoids a Firebase ZipBuilder bug that otherwise declares
`FirebaseCore` twice with different local sources.

It intentionally builds the complete dependency closure. Shipping only
`FirebaseCore.xcframework` and `FirebaseCrashlytics.xcframework` will fail at
link time because Crashlytics also depends on Firebase Installations, Sessions,
Remote Config interop, Google Utilities, Google Data Transport, nanopb, and
PromisesObjC.

## Requirements

- macOS with a Firebase-compatible Xcode selected by `xcode-select`
- CocoaPods 1.12 or newer
- Git and network access to GitHub/CocoaPods
- enough free space for all platform builds

> CocoaPods must be installed on the machine that builds the binaries because
> Firebase's official `zip-builder` uses podspecs to create its temporary Xcode
> projects. Applications consuming the resulting XCFrameworks do not need
> CocoaPods.

Check the selected toolchain before starting:

```bash
xcodebuild -version
xcode-select -p
pod --version
```

## Build iOS device + simulator + Mac Catalyst

```bash
chmod +x ./build-firebase-xcframeworks.sh
./build-firebase-xcframeworks.sh \
  git@github.com:firebase/firebase-ios-sdk.git \
  12.17.0 \
  "ios" \
  "$PWD/build"
```

Firebase 12.17.0 requires Xcode 26.2 or newer. With Xcode 16.0, use Firebase
11.11.0 instead:

```bash
./build-firebase-xcframeworks.sh \
  git@github.com:firebase/firebase-ios-sdk.git \
  11.11.0 \
  "ios" \
  "$PWD/build"
```

To omit Catalyst:

```bash
INCLUDE_CATALYST=0 ./build-firebase-xcframeworks.sh \
  git@github.com:firebase/firebase-ios-sdk.git 12.17.0 "ios" "$PWD/build"
```

To build every supported platform:

```bash
./build-firebase-xcframeworks.sh \
  git@github.com:firebase/firebase-ios-sdk.git \
  12.17.0 \
  "ios macos tvos watchos" \
  "$PWD/build"
```

The script updates the CocoaPods specs repo by default. Set
`UPDATE_POD_REPO=0` only when the local specs cache already contains the
selected Firebase release. Set `KEEP_BUILD_ARTIFACTS=1` when diagnosing a
failed build.

The output contains:

- `Frameworks/` — all required `.xcframework` bundles;
- `CrashlyticsTools/run` and `upload-symbols` — dSYM upload tools;
- `Frameworks.zip` — raw output from Firebase's builder;
- a combined archive plus SHA-256 and SwiftPM checksums.

When integrating manually, add every XCFramework from `Frameworks/` and use
static linking. Do not embed the static frameworks. Add the Crashlytics run
script as the final build phase and configure its input files according to the
Firebase Crashlytics documentation for your Xcode version.

The combined archive is a distribution bundle, not a single SwiftPM
`.binaryTarget`: SwiftPM binary targets require a separate archive/checksum per
artifact plus an explicit dependency graph.

