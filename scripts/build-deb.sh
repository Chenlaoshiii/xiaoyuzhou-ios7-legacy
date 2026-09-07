#!/bin/bash
# Build a .deb for jailbroken iOS. Prefer Theos when available.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
OUTDIR="$ROOT/dist"
APP_NAME="XiaoyuzhouLegacy"
BUNDLE_ID="com.lars.xiaoyuzhoulegacy"
VERSION="1.0.0"
mkdir -p "$OUTDIR"

echo "==> 小宇宙 Legacy .deb 打包脚本"
echo "    项目: $ROOT"

BUILT_DEB=""
if [ -n "${THEOS:-}" ] && [ -f "${THEOS}/makefiles/common.mk" ]; then
  echo "==> 检测到 Theos，尝试 make package..."
  if make package FINALPACKAGE=1; then
    BUILT_DEB=$(ls -t packages/*.deb 2>/dev/null | head -1 || true)
  else
    echo "警告: Theos 编译失败（常见原因：缺少 iPhoneOS SDK），改为占位打包"
  fi
fi

if [ -n "${BUILT_DEB:-}" ] && [ -f "$BUILT_DEB" ]; then
  cp "$BUILT_DEB" "$OUTDIR/"
  echo "==> 完成: $OUTDIR/$(basename "$BUILT_DEB")"
  exit 0
fi

echo "==> 生成布局 .deb（占位二进制；请在 Mac+Theos+iOS7 SDK 上替换为真实 Mach-O）"
STAGE="$OUTDIR/stage"
rm -rf "$STAGE"
mkdir -p "$STAGE/Applications/${APP_NAME}.app"
mkdir -p "$STAGE/DEBIAN"

cp -R "$ROOT/Resources/." "$STAGE/Applications/${APP_NAME}.app/" 2>/dev/null || true
# remove nested Icons dup path confusion — keep Icons/ and root icons
printf '#!/bin/sh\necho "Placeholder — rebuild with Theos on Mac"\n' > "$STAGE/Applications/${APP_NAME}.app/${APP_NAME}"
chmod 755 "$STAGE/Applications/${APP_NAME}.app/${APP_NAME}"
cat > "$STAGE/Applications/${APP_NAME}.app/README_BINARY.txt" << 'EON'
此包内为占位可执行文件，不能在设备上运行。
请在安装 Theos + iOS 7 SDK 的 Mac 上执行:
  cd xiaoyuzhou-ios7 && make package FINALPACKAGE=1
使用 packages/*.deb 安装到越狱设备。
EON

cp "$ROOT/layout/DEBIAN/control" "$STAGE/DEBIAN/control"
cp "$ROOT/layout/DEBIAN/postinst" "$STAGE/DEBIAN/postinst"
cp "$ROOT/layout/DEBIAN/postrm" "$STAGE/DEBIAN/postrm"
chmod 755 "$STAGE/DEBIAN/postinst" "$STAGE/DEBIAN/postrm"
SIZE_KB=$(du -sk "$STAGE/Applications" | awk '{print $1}')
grep -q '^Installed-Size:' "$STAGE/DEBIAN/control" || echo "Installed-Size: $SIZE_KB" >> "$STAGE/DEBIAN/control"

DEB_NAME="${BUNDLE_ID}_${VERSION}_iphoneos-arm.deb"
if command -v dpkg-deb >/dev/null 2>&1; then
  dpkg-deb -b "$STAGE" "$OUTDIR/$DEB_NAME"
else
  TMP="$OUTDIR/deb-tmp"
  rm -rf "$TMP"; mkdir -p "$TMP"
  ( cd "$STAGE" && tar czf "$TMP/data.tar.gz" Applications )
  ( cd "$STAGE/DEBIAN" && tar czf "$TMP/control.tar.gz" . )
  echo "2.0" > "$TMP/debian-binary"
  ( cd "$TMP" && ar r "$OUTDIR/$DEB_NAME" debian-binary control.tar.gz data.tar.gz )
fi

echo "==> 已生成: $OUTDIR/$DEB_NAME"
ls -la "$OUTDIR/$DEB_NAME"
