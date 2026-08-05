#!/bin/bash

set -euo pipefail

# Build a binary XCFramework bundle for FirebaseCore + FirebaseCrashlytics
# using Firebase's own ReleaseTooling/zip-builder.
#
# Usage:
#   ./build-firebase-xcframeworks.sh [repository] [git-ref] [platforms] [output-root]
#
# Example:
#   ./build-firebase-xcframeworks.sh \
#     git@github.com:firebase/firebase-ios-sdk.git \
#     12.17.0 \
#     "ios" \
#     "$PWD/build"
#
# Supported platform names: ios macos tvos watchos

REPOSITORY="${1:-git@github.com:firebase/firebase-ios-sdk.git}"
GIT_REF="${2:-12.17.0}"
PLATFORMS_STRING="${3:-ios}"
OUTPUT_ROOT="${4:-$PWD/firebase-binaries}"
FIREBASE_VERSION="${FIREBASE_VERSION:-${GIT_REF#CocoaPods-}}"
FIREBASE_VERSION="${FIREBASE_VERSION#v}"

MIN_IOS_VERSION="${MIN_IOS_VERSION:-15.0}"
MIN_MACOS_VERSION="${MIN_MACOS_VERSION:-10.15}"
MIN_TVOS_VERSION="${MIN_TVOS_VERSION:-15.0}"
MIN_WATCHOS_VERSION="${MIN_WATCHOS_VERSION:-7.0}"
INCLUDE_CATALYST="${INCLUDE_CATALYST:-1}"
UPDATE_POD_REPO="${UPDATE_POD_REPO:-1}"
KEEP_BUILD_ARTIFACTS="${KEEP_BUILD_ARTIFACTS:-0}"

fail() {
  echo "error: $*" >&2
  exit 1
}

for tool in git xcodebuild swift pod ditto shasum; do
  command -v "$tool" >/dev/null 2>&1 || fail "required tool is not installed: $tool"
done

case " $PLATFORMS_STRING " in
  *" ios "*|*" macos "*|*" tvos "*|*" watchos "*) ;;
  *) fail "platforms must contain one or more of: ios macos tvos watchos" ;;
esac

for platform in $PLATFORMS_STRING; do
  case "$platform" in
    ios|macos|tvos|watchos) ;;
    *) fail "unsupported platform: $platform" ;;
  esac
done

REF_SAFE="$(printf '%s' "$GIT_REF" | tr '/:@ ' '----')"
BUILD_ROOT="${BUILD_ROOT:-${TMPDIR:-/tmp}/firebase-xcframework-builder}"
SOURCE_DIR="${SOURCE_DIR:-$BUILD_ROOT/firebase-ios-sdk-$REF_SAFE}"
FINAL_DIR="$OUTPUT_ROOT/$REF_SAFE"
ZIP_BUILDER_OUTPUT="$BUILD_ROOT/zip-builder-output-$REF_SAFE"
ZIP_PODS_JSON="$BUILD_ROOT/firebase-pods-$REF_SAFE.json"

if [ -e "$FINAL_DIR" ]; then
  fail "output already exists: $FINAL_DIR (remove it explicitly before rebuilding)"
fi

mkdir -p "$BUILD_ROOT" "$OUTPUT_ROOT"

if [ ! -d "$SOURCE_DIR/.git" ]; then
  echo "Cloning $REPOSITORY..."
  git clone --filter=blob:none "$REPOSITORY" "$SOURCE_DIR"
else
  if [ -n "$(git -C "$SOURCE_DIR" status --porcelain)" ]; then
    fail "source checkout has local changes: $SOURCE_DIR"
  fi
  echo "Updating existing checkout..."
  git -C "$SOURCE_DIR" fetch --tags --prune origin
fi

git -C "$SOURCE_DIR" checkout --detach "$GIT_REF"

case "$FIREBASE_VERSION" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) fail "cannot derive a CocoaPods version from git ref '$GIT_REF'; set FIREBASE_VERSION explicitly" ;;
esac

cat >"$ZIP_PODS_JSON" <<JSON
[
  { "name": "FirebaseCore", "version": "$FIREBASE_VERSION", "platforms": ["ios", "macos", "tvos", "watchos"] },
  { "name": "FirebaseCrashlytics", "version": "$FIREBASE_VERSION", "platforms": ["ios", "macos", "tvos", "watchos"] }
]
JSON

mkdir -p "$ZIP_BUILDER_OUTPUT"

ZIP_ARGS=(
  --zip-pods "$ZIP_PODS_JSON"
  --platforms
)

for platform in $PLATFORMS_STRING; do
  ZIP_ARGS+=("$platform")
done

ZIP_ARGS+=(
  --minimum-ios-version "$MIN_IOS_VERSION"
  --minimum-mac-os-version "$MIN_MACOS_VERSION"
  --minimum-tvos-version "$MIN_TVOS_VERSION"
  --minimum-watch-os-version "$MIN_WATCHOS_VERSION"
  --output-dir "$ZIP_BUILDER_OUTPUT"
)

if [ "$INCLUDE_CATALYST" = "0" ]; then
  ZIP_ARGS+=(--no-include-catalyst)
fi

if [ "$UPDATE_POD_REPO" = "0" ]; then
  ZIP_ARGS+=(--no-update-pod-repo)
fi

if [ "$KEEP_BUILD_ARTIFACTS" = "1" ]; then
  ZIP_ARGS+=(--keep-build-artifacts)
fi

echo "Building FirebaseCore, FirebaseCrashlytics, and their binary dependencies..."
(
  cd "$SOURCE_DIR/ReleaseTooling"
  swift run -c release zip-builder "${ZIP_ARGS[@]}"
)

FRAMEWORKS_ZIP="$ZIP_BUILDER_OUTPUT/Frameworks.zip"
[ -f "$FRAMEWORKS_ZIP" ] || fail "zip-builder did not create $FRAMEWORKS_ZIP"

mkdir -p "$FINAL_DIR/Frameworks" "$FINAL_DIR/CrashlyticsTools"
ditto -x -k "$FRAMEWORKS_ZIP" "$FINAL_DIR/Frameworks"

for tool in run upload-symbols CrashlyticsInputFiles.xcfilelist; do
  cp "$SOURCE_DIR/Crashlytics/$tool" "$FINAL_DIR/CrashlyticsTools/$tool"
done
chmod +x "$FINAL_DIR/CrashlyticsTools/run" "$FINAL_DIR/CrashlyticsTools/upload-symbols"

cp "$FRAMEWORKS_ZIP" "$FINAL_DIR/Frameworks.zip"
git -C "$SOURCE_DIR" rev-parse HEAD >"$FINAL_DIR/firebase-ios-sdk.commit"
xcodebuild -version >"$FINAL_DIR/xcode-version.txt"
pod --version >"$FINAL_DIR/cocoapods-version.txt"

PACKAGE_ZIP="$OUTPUT_ROOT/FirebaseCoreCrashlytics-$REF_SAFE.zip"
ditto -c -k --keepParent "$FINAL_DIR" "$PACKAGE_ZIP"

(
  cd "$OUTPUT_ROOT"
  shasum -a 256 "$(basename "$PACKAGE_ZIP")" >"$(basename "$PACKAGE_ZIP").sha256"
)
swift package compute-checksum "$PACKAGE_ZIP" >"$PACKAGE_ZIP.swiftpm-checksum"

echo
echo "Build complete:"
echo "  XCFrameworks: $FINAL_DIR/Frameworks"
echo "  Crashlytics tools: $FINAL_DIR/CrashlyticsTools"
echo "  Archive: $PACKAGE_ZIP"
echo "  SHA-256: $PACKAGE_ZIP.sha256"
echo "  SwiftPM checksum: $PACKAGE_ZIP.swiftpm-checksum"

