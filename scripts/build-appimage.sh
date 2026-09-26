#!/usr/bin/env bash
# Package a built Flutter Linux bundle as an AppImage using appimagetool.
#
# Usage: scripts/build-appimage.sh <bundle-dir> <output-file>
set -euo pipefail

BUNDLE_DIR="${1:?usage: build-appimage.sh <bundle-dir> <output-file>}"
OUT="${2:?usage: build-appimage.sh <bundle-dir> <output-file>}"

APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"

APPDIR="$(mktemp -d)/Pastfinder.AppDir"
trap 'rm -rf "$(dirname "$APPDIR")"' EXIT
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/icons/hicolor/512x512/apps" \
  "$APPDIR/usr/share/applications"

cp -r "$BUNDLE_DIR/." "$APPDIR/usr/bin/"

cat > "$APPDIR/pastfinder.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Pastfinder
Exec=pastfinder
Icon=pastfinder
Categories=Utility;
DESKTOP

cp linux/runner/resources/pastfinder.png "$APPDIR/pastfinder.png"
cp linux/runner/resources/pastfinder.png \
  "$APPDIR/usr/share/icons/hicolor/512x512/apps/pastfinder.png"
cp "$APPDIR/pastfinder.desktop" "$APPDIR/usr/share/applications/"

ln -sf usr/bin/pastfinder "$APPDIR/AppRun"

if ! command -v appimagetool >/dev/null 2>&1; then
  curl -fsSL --retry 3 -o /tmp/appimagetool "$APPIMAGETOOL_URL"
  chmod +x /tmp/appimagetool
  APPIMAGETOOL=/tmp/appimagetool
else
  APPIMAGETOOL=appimagetool
fi

ARCH=x86_64 "$APPIMAGETOOL" "$APPDIR" "$OUT"
