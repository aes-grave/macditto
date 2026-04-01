#!/bin/sh
set -eu

if [ ! -d "MacDitto.xcodeproj" ]; then
  echo "Generate the Xcode project first with ./scripts/bootstrap-mac.sh"
  exit 1
fi

xcodebuild \
  -project MacDitto.xcodeproj \
  -scheme MacDitto \
  -configuration Release \
  -destination "generic/platform=macOS" \
  archive \
  -archivePath build/MacDitto.xcarchive
