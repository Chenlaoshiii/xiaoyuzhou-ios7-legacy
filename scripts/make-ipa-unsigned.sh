#!/bin/bash
# 生成未签名 IPA（fake-sign with minimal entitlements）。可用 AppSync Unified 安装。
# Usage: ./scripts/make-ipa-unsigned.sh [path/to/XiaoyuzhouLegacy.app]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${1:-}"
OUTDIR="$ROOT/dist"
mkdir -p "$OUTDIR"
if [ -z "$APP" ]; then
  CAND=$(find "$ROOT/.theos" "$ROOT" -type d -name 'XiaoyuzhouLegacy.app' 2>/dev/null | head -1 || true)
  APP="$CAND"
fi
if [ -z "$APP" ] || [ ! -d "$APP" ]; then
  echo "用法: $0 /path/to/XiaoyuzhouLegacy.app"
  echo "未找到已编译的 .app。请先 make / make package。"
  exit 1
fi
STAGE="$OUTDIR/ipa-stage"
rm -rf "$STAGE"
mkdir -p "$STAGE/Payload"
cp -R "$APP" "$STAGE/Payload/"

# Ensure icons at bundle root (iOS 7 SpringBoard)
APPDIR="$STAGE/Payload/XiaoyuzhouLegacy.app"
for ic in Icon.png Icon@2x.png Icon-60@2x.png Icon-Small.png Icon-Small@2x.png Icon-Small-40@2x.png; do
  if [ ! -f "$APPDIR/$ic" ] && [ -f "$ROOT/Resources/$ic" ]; then
    cp "$ROOT/Resources/$ic" "$APPDIR/$ic"
  fi
  if [ ! -f "$APPDIR/Icons/$ic" ] && [ -f "$ROOT/Resources/Icons/$ic" ]; then
    mkdir -p "$APPDIR/Icons"
    cp "$ROOT/Resources/Icons/$ic" "$APPDIR/Icons/$ic"
  fi
done

# Fake-sign with MINIMAL entitlements (NOT platform-application)
ENT="$ROOT/ipa-ent.plist"
if [ ! -f "$ENT" ]; then ENT="$ROOT/ent.plist"; fi
BIN="$APPDIR/XiaoyuzhouLegacy"
LDID_BIN=""
if command -v ldid >/dev/null 2>&1; then LDID_BIN=$(command -v ldid); fi
if [ -z "$LDID_BIN" ] && [ -x "${THEOS:-/home/box/theos}/toolchain/linux/iphone/bin/ldid" ]; then
  LDID_BIN="${THEOS:-/home/box/theos}/toolchain/linux/iphone/bin/ldid"
fi
if [ -n "$LDID_BIN" ] && [ -f "$BIN" ]; then
  echo "==> ldid fake-sign with $ENT"
  "$LDID_BIN" -S"$ENT" "$BIN"
  echo "==> entitlements now:"
  "$LDID_BIN" -e "$BIN" || true
else
  echo "警告: 未找到 ldid，IPA 可能无法在设备上启动"
fi

rm -f "$OUTDIR/XiaoyuzhouLegacy-unsigned.ipa"
(
  cd "$STAGE"
  zip -qr "$OUTDIR/XiaoyuzhouLegacy-unsigned.ipa" Payload
)
echo "==> 未签名 IPA: $OUTDIR/XiaoyuzhouLegacy-unsigned.ipa"
ls -la "$OUTDIR/XiaoyuzhouLegacy-unsigned.ipa"
echo "    安装建议: Cydia 添加 https://cydia.akemi.ai/ 安装 AppSync Unified，再用 Filza 安装。"
echo "    更推荐: 使用 .deb 安装到 /Applications。"
