#!/usr/bin/env bash
# build-android-all.sh — builds the three companion Android APKs
# sequentially (shared gradle cache). Idempotent: skips projects whose
# APK already exists unless --rebuild is passed.
set -uo pipefail
W="/home/rex/Documentos/Software Development/DeepSeek Harness"
export ANDROID_HOME="/home/rex/Descargas/androidsdk"
export ANDROID_USER_HOME="$W/.android"
export GRADLE_USER_HOME="$W/.gradle"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk-amd64}"
REBUILD="${1:-}"

build_one() { # $1 = project dir, $2 = expected apk name
  local proj="$1" apk="$2"
  if [ -f "$W/$apk" ] && [ "$REBUILD" != "--rebuild" ]; then
    echo "[build] SKIP $proj ($apk exists)"
    return 0
  fi
  echo "[build] $proj: gradle assembleRelease"
  (cd "$W/$proj/android" && ./gradlew assembleRelease --console=plain 2>&1 | tail -4) || { echo "[build] FAILED $proj"; return 1; }
  local out
  out=$(ls "$W/$proj/android/app/build/outputs/apk/release/"*.apk 2>/dev/null | head -1)
  if [ -z "$out" ]; then echo "[build] FAILED $proj (no apk output)"; return 1; fi
  cp "$out" "$W/$apk"
  echo "[build] OK $proj -> $apk ($(du -h "$W/$apk" | cut -f1))"
}

build_one subtitle-toolkit-android Subtitle-Toolkit-0.2.0-android.apk
build_one kitchenos-android KitchenOS-Premium-0.6.0-android.apk
build_one shikibu-android Shikibu-1.0.0-android.apk
echo "[build] all done"
