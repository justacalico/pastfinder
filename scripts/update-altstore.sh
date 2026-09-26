#!/usr/bin/env bash
# Regenerate altstore/apps.json from the latest GitLab release and commit it
# back to main over SSH (deploy key) with ci.skip.
set -euo pipefail

RELEASE_TAG="${RELEASE_TAG:-}"
[ -n "$RELEASE_TAG" ] || { echo "RELEASE_TAG not set, skipping"; exit 0; }

PACKAGE_URL="https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/packages/generic/release-assets/${RELEASE_TAG}/pastfinder-ios-arm64-unsigned.ipa"
ICON_URL="https://gitlab.com/HttpAnimations/pastfinder/-/raw/main/assets/icon/icon-1024.png"

SIZE=$(curl -fsSI "$PACKAGE_URL" 2>/dev/null | tr -d '\r' | awk 'tolower($1)=="content-length:"{print $2}' || true)
[ -n "$SIZE" ] || SIZE=0

VERSION="${RELEASE_TAG#v}"
DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)

mkdir -p altstore
cat > altstore/apps.json <<EOF
{
  "name": "Pastfinder",
  "identifier": "com.httpanimations.pastfinder.source",
  "sourceURL": "https://httpanimations.gitlab.io/pastfinder/altstore/apps.json",
  "apps": [
    {
      "name": "Pastfinder",
      "bundleIdentifier": "com.httpanimations.pastfinder",
      "developerName": "HttpAnimations",
      "iconURL": "$ICON_URL",
      "tintedIconURL": "$ICON_URL",
      "versions": [
        {
          "version": "$VERSION",
          "date": "$DATE",
          "downloadURL": "$PACKAGE_URL",
          "size": $SIZE,
          "minOSVersion": "15.0"
        }
      ]
    }
  ]
}
EOF

# Commit back to main via the release deploy key. Requires the deploy key to
# be allowed to push to the protected main branch.
git config user.name "GitLab CI"
git config user.email "ci@gitlab.com"
git remote add gitlab-ssh "git@gitlab.com:${CI_PROJECT_PATH}.git" 2>/dev/null || true
git fetch gitlab-ssh main
git checkout -B altstore-update "gitlab-ssh/main" 2>/dev/null || git checkout -B altstore-update main
git add altstore/apps.json
if git diff --cached --quiet; then
  echo "AltStore source already up to date"
else
  git commit -m "chore: 更新 AltStore 源"
  git push -o ci.skip gitlab-ssh altstore-update:main
fi
