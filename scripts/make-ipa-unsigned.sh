#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${1:-}"
OUTDIR="$ROOT/dist"
mkdir -p "$OUTDIR"
if [ -z "$APP" ]; then
  if [ -d "$ROOT/.theos/_/Applications/XiaoyuzhouLegacy.app" ]; then
    APP="$ROOT/.theos/_/Applications/XiaoyuzhouLegacy.app"
  else
    APP=$(find "$ROOT/.theos/obj" -maxdepth 1 -type d -name 'XiaoyuzhouLegacy.app' 2>/dev/null | head -1 || true)
  fi
fi
STAGE="$OUTDIR/ipa-stage"
rm -rf "$STAGE"
mkdir -p "$STAGE/Payload"
cp -R "$APP" "$STAGE/Payload/"
APPDIR="$STAGE/Payload/XiaoyuzhouLegacy.app"
rm -rf "$APPDIR"/*.dSYM
ENT="$ROOT/ipa-ent.plist"
BIN="$APPDIR/XiaoyuzhouLegacy"
LDID="${THEOS:-/home/box/theos}/toolchain/linux/iphone/bin/ldid"
chmod 0755 "$BIN"
"$LDID" -S"$ENT" -Hsha1 "$BIN"
"$LDID" -e "$BIN" || true
find "$APPDIR" -iname 'iTunesArtwork*' -delete
# Ensure launch images + icons present
ls -la "$APPDIR"/Default*.png "$APPDIR"/Icon*.png >/dev/null
rm -f "$OUTDIR/XiaoyuzhouLegacy-unsigned.ipa"
(cd "$STAGE" && zip -qr "$OUTDIR/XiaoyuzhouLegacy-unsigned.ipa" Payload)
cp -f "$OUTDIR/XiaoyuzhouLegacy-unsigned.ipa" /workspace/Xiaoyuzhou-爱思助手.ipa
cp -f "$OUTDIR/XiaoyuzhouLegacy-unsigned.ipa" /workspace/Xiaoyuzhou-i4tools.ipa
cp -f "$OUTDIR/XiaoyuzhouLegacy-unsigned.ipa" /workspace/Xiaoyuzhou-native-i4tools.ipa
ls -la "$OUTDIR/XiaoyuzhouLegacy-unsigned.ipa" /workspace/Xiaoyuzhou-爱思助手.ipa /workspace/Xiaoyuzhou-i4tools.ipa /workspace/Xiaoyuzhou-native-i4tools.ipa
