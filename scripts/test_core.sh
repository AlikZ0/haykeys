#!/bin/bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Эта команда использует инструменты Xcode на Mac или macOS runner в GitHub Actions."
    exit 1
fi

haykeys_root="$(cd "$(dirname "$0")/.." && pwd)"
haykeys_tests_dir="$(mktemp -d "${TMPDIR:-/tmp}/haykeys-core.XXXXXX")"
trap 'rm -rf "$haykeys_tests_dir"' EXIT

xcrun swiftc -swift-version 5 \
    "$haykeys_root/Core/KeyboardLayout.swift" \
    "$haykeys_root/Core/KeyboardState.swift" \
    "$haykeys_root/Core/WordSuggestions.swift" \
    "$haykeys_root/Tests/main.swift" \
    -o "$haykeys_tests_dir/core-checks"
"$haykeys_tests_dir/core-checks"
