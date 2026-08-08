#!/usr/bin/env bash
#
# Build + emda + tanzeel fe /Applications fe amr wa7ed.
#
# Leh el emda mohimma:
#   El emda el "ad-hoc" (el default fe Flutter) bete5alli el shart bta3 el
#   nizam yeb2a el hash bta3 el binary nafso:
#       designated => cdhash H"dd7f65..."
#   ya3ni kol build gedeed = hash gedeed = ezn el Accessibility yemoot, w el
#   zorar fe el Settings yefdal shakloh mafto7 bas mesh sha8al fe3lan.
#
#   Lama nemdi be certificate 7a2i2i, el shart beyeb2a:
#       designated => identifier "com.ahmed.clipboard" and ... certificate leaf ...
#   mafeesh hash khales — fa el ezn beye3eesh ma3a kol el builds el gaya.
#
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="2as w Laze2"
APP="build/macos/Build/Products/Release/${APP_NAME}.app"
DEST="/Applications/${APP_NAME}.app"

# Momken te7add el certificate bta3ak keda:
#   CLIPBOARD_SIGN_IDENTITY="Developer ID Application: ..." ./tool/install.sh
IDENTITY="${CLIPBOARD_SIGN_IDENTITY:-$(
  security find-identity -v -p codesigning |
    awk -F'"' '/Developer ID Application|Apple Development/ { print $2; exit }'
)}"

if [ -z "$IDENTITY" ]; then
  echo "Mafeesh certificate lel emda fel keychain." >&2
  echo "Shoof el mawgood 3andak be: security find-identity -v -p codesigning" >&2
  exit 1
fi

echo "==> Signing identity: $IDENTITY"

flutter build macos --release

echo "==> Emda"
codesign --force --deep --sign "$IDENTITY" "$APP"
codesign --verify --deep --strict "$APP"

echo "==> Tanzeel fe $DEST"
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 1
rm -rf "$DEST"
# `ditto` mesh `cp -R`: howa elly bey-na2el el bundle bel metadata bta3et el
# emda sa7 min gher ma yekasarha.
ditto "$APP" "$DEST"

open "$DEST"
echo "==> Khalas. El shart el 7ali:"
codesign -d -r- "$DEST" 2>&1 | grep designated
