#!/usr/bin/env bash
# Sync version across all locations from pubspec.yaml.
# Usage: ./scripts/sync_version.sh [--check]
#   No args: read pubspec.yaml and update app_version.dart + README badge
#   --check: verify consistency, exit 1 if mismatched (for CI)

set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | cut -d+ -f1 | tr -d ' ')
SEMVER="${VERSION%%+*}"  # e.g. "2.0.3" from "2.0.3+43"

if [ "${1:-}" = "--check" ]; then
    ERRORS=0

    # Check app_version.dart
    DART_VER=$(grep "const String appVersion" lib/app_version.dart | grep -o "'[^']*'" | tr -d "'")
    if [ "$DART_VER" != "$SEMVER" ]; then
        echo "❌ app_version.dart: $DART_VER != pubspec.yaml: $SEMVER"
        ERRORS=$((ERRORS + 1))
    fi

    # Check README badge
    README_VER=$(grep -o 'version-[0-9.]*' README.md | head -1 | sed 's/version-//')
    if [ "$README_VER" != "$SEMVER" ]; then
        echo "❌ README.md badge: $README_VER != pubspec.yaml: $SEMVER"
        ERRORS=$((ERRORS + 1))
    fi

    if [ $ERRORS -gt 0 ]; then
        echo "Run ./scripts/sync_version.sh to fix."
        exit 1
    fi
    echo "✅ All version labels consistent ($SEMVER)"
    exit 0
fi

# Update app_version.dart
sed -i "s/const String appVersion = '[^']*';/const String appVersion = '$SEMVER';/" lib/app_version.dart
echo "✅ app_version.dart → $SEMVER"

# Update README badge
sed -i "s/version-[0-9.]*-blue/version-$SEMVER-blue/" README.md
echo "✅ README.md badge → $SEMVER"

echo "Done. Commit and push to apply."
