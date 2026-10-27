#!/bin/bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Нужен Mac с полной версией Xcode и установленным iOS Simulator SDK."
    exit 1
fi

haykeys_root="$(cd "$(dirname "$0")/.." && pwd)"
haykeys_check_dir="$(mktemp -d "${TMPDIR:-/tmp}/haykeys-check.XXXXXX")"
trap 'rm -rf "$haykeys_check_dir"' EXIT

bash "$haykeys_root/scripts/test_core.sh"

xcodebuild \
    -project "$haykeys_root/HayKeys.xcodeproj" \
    -scheme HayKeys \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$haykeys_check_dir/DerivedData" \
    CODE_SIGNING_ALLOWED=NO \
    build
