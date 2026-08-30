#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v gradle >/dev/null 2>&1; then
  echo "Gradle is required once to generate the wrapper. Install Gradle, then rerun: bash android/bootstrap-gradle-wrapper.sh" >&2
  exit 1
fi

gradle wrapper --gradle-version 8.11.1 --distribution-type bin

echo "Gradle wrapper generated. Commit gradlew, gradlew.bat, gradle/wrapper/gradle-wrapper.properties, and gradle/wrapper/gradle-wrapper.jar."
