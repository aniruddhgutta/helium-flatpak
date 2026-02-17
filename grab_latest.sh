#!/bin/sh
set -eu

MANIFEST_FILE="com.imputnet.Helium.yml"
METADATA_FILE="com.imputnet.Helium.metainfo.xml"
REPO_URL="https://github.com/imputnet/helium-linux/releases/download"
ALLOW_PRERELEASE=$(grep -m1 'allow-prerelease:' fetch.config.yml | awk '{print $2}')

# --- Set prerelease behaviour ---
if [ "$ALLOW_PRERELEASE" = "true" ]; then
    FILTER=".prerelease == true or .prerelease == false"
else
    FILTER=".prerelease == false"
fi

# --- Fetch latest Helium release ---
LATEST_JSON=$(curl -s https://api.github.com/repos/imputnet/helium-linux/releases \
  | jq -c "[.[] | select(.tag_name != null and ($FILTER))] | sort_by(.created_at) | last")

LATEST_VERSION=$(echo "$LATEST_JSON" | jq -r '.tag_name')
IS_PRERELEASE=$(echo "$LATEST_JSON" | jq -r '.prerelease')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
  echo "   Failed to fetch latest version tag from GitHub."
  exit 1
fi

if [ "$IS_PRERELEASE" = "true" ]; then
  echo "   Latest release is a prerelease: $LATEST_VERSION"
else
  echo "   Latest release is a stable release: $LATEST_VERSION"
fi

# --- Extract current version from manifest ---
CURRENT_VERSION=$(grep -o 'helium-[0-9]*\.[0-9]*\.[0-9]*\(\.[0-9]*\)\?' "$MANIFEST_FILE" \
  | head -n1 \
  | grep -o '[0-9]*\.[0-9]*\.[0-9]*\(\.[0-9]*\)\?')

CURRENT_DATE=$(date '+%Y-%m-%d')

# --- Create temp file with version number ---
printf "version: %s\nprerelease: %s\n" "$CURRENT_VERSION" "$IS_PRERELEASE" > version.txt

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
  echo "   Manifest already up to date ($CURRENT_VERSION). Checking SHA256..."
else
  echo "   Updating manifest from $CURRENT_VERSION → $LATEST_VERSION"
  
  # --- Replace version strings ---
  sed "s|helium-linux/releases/download/${CURRENT_VERSION}|helium-linux/releases/download/${LATEST_VERSION}|g" "$MANIFEST_FILE" > "$MANIFEST_FILE.tmp" && mv "$MANIFEST_FILE.tmp" "$MANIFEST_FILE"
  sed "s|helium-${CURRENT_VERSION}-x86_64_linux|helium-${LATEST_VERSION}-x86_64_linux|g" "$MANIFEST_FILE" > "$MANIFEST_FILE.tmp" && mv "$MANIFEST_FILE.tmp" "$MANIFEST_FILE"
  sed "s|helium-${CURRENT_VERSION}\([^-]\)|helium-${LATEST_VERSION}\1|g" "$MANIFEST_FILE" > "$MANIFEST_FILE.tmp" && mv "$MANIFEST_FILE.tmp" "$MANIFEST_FILE"
  sed "s|version=\"${CURRENT_VERSION}\"|version=\"${LATEST_VERSION}\"|g" "$METADATA_FILE" > "$METADATA_FILE.tmp" && mv "$METADATA_FILE.tmp" "$METADATA_FILE"
  sed "s|date=\"[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\"|date=\"${CURRENT_DATE}\"|g" "$METADATA_FILE" > "$METADATA_FILE.tmp" && mv "$METADATA_FILE.tmp" "$METADATA_FILE"
  
  # --- Update version number ---
  printf "version: %s\nprerelease: %s\n" "$LATEST_VERSION" "$IS_PRERELEASE" > version.txt
fi

# --- Compute new SHA256 ---
DOWNLOAD_URL="$REPO_URL/$LATEST_VERSION/helium-$LATEST_VERSION-x86_64_linux.tar.xz"
echo "   Downloading $DOWNLOAD_URL to compute sha256..."
TMP_FILE=$(mktemp)
curl -L -s -o "$TMP_FILE" "$DOWNLOAD_URL"
NEW_SHA256=$(sha256sum "$TMP_FILE" | awk '{print $1}')
rm -f "$TMP_FILE"

if [ -z "$NEW_SHA256" ]; then
  echo "   Failed to compute SHA256 checksum."
  exit 1
fi

echo "   New SHA256: $NEW_SHA256"

# --- Replace sha256 field in manifest ---
sed "s/sha256: [a-f0-9]\{64\}/sha256: $NEW_SHA256/" "$MANIFEST_FILE" > "$MANIFEST_FILE.tmp" && mv "$MANIFEST_FILE.tmp" "$MANIFEST_FILE"

# --- Skip if not changed ---
if git diff --quiet -- "$MANIFEST_FILE"; then
  echo "   No effective change detected, skipping commit."
  exit 0
fi

# --- Commit and push if changed ---
git add "$MANIFEST_FILE" "$METADATA_FILE"
git commit -m "update: helium ${LATEST_VERSION}"
git push origin main

echo "   Changes committed and pushed: update: helium ${LATEST_VERSION}"
