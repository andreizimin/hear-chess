#!/bin/bash
# Builds hear-chess and installs it on the iPhone connected to this Mac by cable.
# Usage: HEARCHESS_TEAM_ID=<your Apple team ID> ./run-on-iphone.sh
#   Optional: HEARCHESS_BUNDLE_ID (default dev.hearchess.trainer.<your user name>)
set -euo pipefail
cd "$(dirname "$0")"

: "${HEARCHESS_TEAM_ID:?Set HEARCHESS_TEAM_ID to your Apple team ID (Xcode > Settings > Accounts)}"
export HEARCHESS_TEAM_ID
export HEARCHESS_BUNDLE_ID="${HEARCHESS_BUNDLE_ID:-dev.hearchess.trainer.$(whoami | tr -cd 'a-z0-9')}"

if ! command -v xcodegen >/dev/null; then
  echo "Installing XcodeGen with Homebrew…"
  brew install xcodegen
fi
xcodegen generate

DEVICE_ID=$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && /physical/ && /connected|available/' \
  | grep -oE '[0-9A-F]{8}-[0-9A-F]{16}|[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}' | head -1)
if [ -z "${DEVICE_ID}" ]; then
  echo "No connected iPhone found. Unlock it, trust this Mac, and turn on Developer Mode." >&2
  xcrun devicectl list devices >&2 || true
  exit 1
fi
echo "iPhone: ${DEVICE_ID}"

xcodebuild -project HearChess.xcodeproj -scheme HearChess -configuration Debug \
  -destination "id=${DEVICE_ID}" -derivedDataPath build -allowProvisioningUpdates build | tail -20

APP=build/Build/Products/Debug-iphoneos/HearChess.app
xcrun devicectl device install app --device "${DEVICE_ID}" "${APP}"
xcrun devicectl device process launch --device "${DEVICE_ID}" "${HEARCHESS_BUNDLE_ID}"
echo "hear-chess is installed and running on the iPhone."
