#!/bin/bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Сборка выполняется на macOS runner GitHub Actions. На Ubuntu используйте workflow Build HayKeys IPA."
    exit 1
fi

haykeys_root="$(cd "$(dirname "$0")/.." && pwd)"
haykeys_output_dir="${1:-$haykeys_root/artifacts}"
mkdir -p "$haykeys_output_dir"
haykeys_output_dir="$(cd "$haykeys_output_dir" && pwd)"
haykeys_build_dir="$(mktemp -d "${TMPDIR:-/tmp}/haykeys-ipa.XXXXXX")"
trap 'rm -rf "$haykeys_build_dir"' EXIT

xcodebuild \
    -project "$haykeys_root/HayKeys.xcodeproj" \
    -scheme HayKeys \
    -configuration Release \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$haykeys_build_dir/DerivedData" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    "CODE_SIGN_IDENTITY=" \
    ARCHS=arm64 \
    ONLY_ACTIVE_ARCH=NO \
    build

haykeys_app="$haykeys_build_dir/DerivedData/Build/Products/Release-iphoneos/HayKeys.app"
haykeys_extension="$haykeys_app/PlugIns/HayKeysKeyboard.appex"
test -f "$haykeys_app/HayKeys"
test -f "$haykeys_extension/HayKeysKeyboard"
test "$(/usr/libexec/PlistBuddy -c 'Print :NSExtension:NSExtensionPointIdentifier' "$haykeys_extension/Info.plist")" = "com.apple.keyboard-service"

mkdir -p "$haykeys_build_dir/package/Payload"
/usr/bin/ditto "$haykeys_app" "$haykeys_build_dir/package/Payload/HayKeys.app"
/usr/bin/ditto -c -k --keepParent \
    "$haykeys_build_dir/package/Payload" \
    "$haykeys_output_dir/HayKeys-unsigned.ipa"

(
    cd "$haykeys_output_dir"
    /usr/bin/shasum -a 256 HayKeys-unsigned.ipa > HayKeys-unsigned.ipa.sha256
)
echo "Created unsigned IPA with its keyboard extension: $haykeys_output_dir/HayKeys-unsigned.ipa"
echo "Use SideStore or iloader to sign it with your own Apple Account before installing."
