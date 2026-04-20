#!/usr/bin/env bash
# Build a signed Android App Bundle (AAB) suitable for upload to Google Play.
#
# IDE-agnostic: uses only cmake/ninja and Qt's CLI tooling (qt-cmake +
# androiddeployqt invoked via Qt's CMake integration). No Qt Creator /
# KDevelop / Android Studio required.
#
# Required environment variables:
#   GPS_INFO_ANDROID_KEYSTORE_PATH    Absolute path to the release keystore.
#   GPS_INFO_ANDROID_KEYSTORE_ALIAS   Key alias inside the keystore.
#   GPS_INFO_ANDROID_KEYSTORE_STORE_PASS  Keystore password.
#   GPS_INFO_ANDROID_KEYSTORE_KEY_PASS    Key password (optional; defaults
#                                         to store password).
#
# Optional environment variables:
#   QT_ANDROID_ROOT   Qt for Android install prefix (arm64 by default).
#                     Default: /opt/android-libs/aarch64
#   ANDROID_SDK_ROOT  Android SDK root.
#                     Default: /opt/android-sdk
#   ANDROID_NDK_ROOT  Android NDK root.
#                     Default: /opt/android-ndk
#   BUILD_DIR         Build directory.
#                     Default: build/play-store-release
#
# Tip: keep credentials in a gitignored file (e.g. android-signing.env) and
#      source it before running:  `set -a; source android-signing.env; set +a`

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." &>/dev/null && pwd)"

: "${QT_ANDROID_ROOT:=/opt/android-libs/aarch64}"
: "${ANDROID_SDK_ROOT:=/opt/android-sdk}"
: "${ANDROID_NDK_ROOT:=/opt/android-ndk}"
: "${BUILD_DIR:=${PROJECT_ROOT}/build/play-store-release}"
# AGP 9.x requires JDK 17. Allow override via env.
: "${JAVA_HOME:=/usr/lib/jvm/java-17-openjdk}"

require_var() {
    local name="$1"
    if [[ -z "${!name:-}" ]]; then
        echo "error: environment variable ${name} is required" >&2
        exit 2
    fi
}

require_var GPS_INFO_ANDROID_KEYSTORE_PATH
require_var GPS_INFO_ANDROID_KEYSTORE_ALIAS
require_var GPS_INFO_ANDROID_KEYSTORE_STORE_PASS
: "${GPS_INFO_ANDROID_KEYSTORE_KEY_PASS:=${GPS_INFO_ANDROID_KEYSTORE_STORE_PASS}}"

if [[ ! -f "${GPS_INFO_ANDROID_KEYSTORE_PATH}" ]]; then
    echo "error: keystore not found at ${GPS_INFO_ANDROID_KEYSTORE_PATH}" >&2
    exit 2
fi

if [[ ! -x "${JAVA_HOME}/bin/javac" ]]; then
    echo "error: JAVA_HOME does not point to a JDK with javac: ${JAVA_HOME}" >&2
    echo "       AGP 9.x requires JDK 17. Install it or export JAVA_HOME." >&2
    exit 2
fi
export JAVA_HOME
export PATH="${JAVA_HOME}/bin:${PATH}"

QT_CMAKE="${QT_ANDROID_ROOT}/bin/qt-cmake"
if [[ ! -x "${QT_CMAKE}" ]]; then
    echo "error: qt-cmake not found at ${QT_CMAKE}" >&2
    echo "       set QT_ANDROID_ROOT to your Qt-for-Android install prefix." >&2
    exit 2
fi

for tool in magick ninja keytool; do
    if ! command -v "${tool}" &>/dev/null; then
        echo "error: required tool '${tool}' is not in PATH" >&2
        exit 2
    fi
done

export ANDROID_SDK_ROOT ANDROID_NDK_ROOT

# androiddeployqt reads the keystore via these env vars (see
# `androiddeployqt --help`). Export them so they are visible to the build step.
export QT_ANDROID_KEYSTORE_PATH="${GPS_INFO_ANDROID_KEYSTORE_PATH}"
export QT_ANDROID_KEYSTORE_ALIAS="${GPS_INFO_ANDROID_KEYSTORE_ALIAS}"
export QT_ANDROID_KEYSTORE_STORE_PASS="${GPS_INFO_ANDROID_KEYSTORE_STORE_PASS}"
export QT_ANDROID_KEYSTORE_KEY_PASS="${GPS_INFO_ANDROID_KEYSTORE_KEY_PASS}"

echo ">>> Project     : ${PROJECT_ROOT}"
echo ">>> Build dir   : ${BUILD_DIR}"
echo ">>> Qt (Android): ${QT_ANDROID_ROOT}"
echo ">>> SDK / NDK   : ${ANDROID_SDK_ROOT} / ${ANDROID_NDK_ROOT}"
echo ">>> JDK         : ${JAVA_HOME}"
echo ">>> Keystore    : ${QT_ANDROID_KEYSTORE_PATH} (alias: ${QT_ANDROID_KEYSTORE_ALIAS})"

mkdir -p "${BUILD_DIR}"

"${QT_CMAKE}" \
    -S "${PROJECT_ROOT}" \
    -B "${BUILD_DIR}" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}" \
    -DANDROID_NDK_ROOT="${ANDROID_NDK_ROOT}" \
    -DGPS_INFO_ANDROID_SIGN=ON

cmake --build "${BUILD_DIR}" --target aab

AAB_PATH="$(find "${BUILD_DIR}/android-build/build/outputs/bundle" -name '*.aab' -print -quit 2>/dev/null || true)"

if [[ -z "${AAB_PATH}" ]]; then
    echo "error: AAB not produced; check build log above" >&2
    exit 1
fi

echo
echo "AAB produced: ${AAB_PATH}"
echo "Upload this file to Google Play Console."
