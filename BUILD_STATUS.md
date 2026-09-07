# BUILD_STATUS — 小宇宙 Legacy（闪退修复 + 官方图标）

**日期**: 2026-09-07（Asia/Shanghai）

## 闪退根因（判断）

1. **主因（IPA / 爱思助手路径）**: 旧包用 `ldid` 签了 `platform-application` + `keychain-access-groups` 等私有权限。经 AppSync/爱思助手装到用户沙盒后，与系统平台应用期望冲突，**一点即闪退**。
2. **次因/风险**: 本机 `iPhoneOS9.3.sdk` 的 `.tbd` 同时列出 arm + i386/x86_64，链接器会警告 “built for iOS Simulator”。当前产物仍是 **thin armv7 / MH_EXECUTE / VERSION_MIN 7.0**，属警告而非错误切片；已加 `compat_memset.c`，并用 `-Wl,-undefined,error` 避免 `dynamic_lookup`。
3. **加固**: AppDelegate / XYZAPIClient 启动路径 try-catch；去掉 NSUUID；推迟 AVAudioSession 激活。

## 本次改动

- `ent.plist` / `ipa-ent.plist` → 仅 `get-task-allow=true`（最小权限）
- IPA 打包脚本在 zip 前对可执行文件执行 `ldid -Sipa-ent.plist`
- 官方 App Icon（brand.xyzfm.space 素材包 `square.png`）生成全部尺寸，放在 **bundle 根** 与 `Icons/`
- `Info.plist`: `CFBundleIconFile=Icon`，`CFBundleIconFiles` 使用无路径基名
- 源码: `compat_memset.c`、AppDelegate 加固、APIClient 去 NSUUID、Player 延迟激活音频会话
- Makefile: `TARGET=iphone:clang:9.3:7.0`，`LDFLAGS=-Wl,-undefined,error`

## 交付物（爱思助手）

| 文件 | 路径 |
|------|------|
| IPA（主） | `/workspace/xiaoyuzhou-ios7/dist/XiaoyuzhouLegacy-unsigned.ipa` |
| IPA（中文名） | `/workspace/Xiaoyuzhou-爱思助手.ipa` |
| deb | `/workspace/xiaoyuzhou-ios7/packages/com.lars.xiaoyuzhoulegacy_1.0.0_iphoneos-arm.deb` |
| 汇总 zip | `/workspace/xiaoyuzhou-ios7-dist.zip` |

爱思助手：导入上述 IPA → 安装到已越狱/已信任设备（需 AppSync 或爱思侧未签名安装能力）。

## 残留风险

- SDK TBD 仍有 simulator 警告；若仍闪退，需在 Mac 正版设备 SDK 上重编。
- TLS/API 在旧 iOS 7 上可能因证书链失败（登录阶段，非启动闪退）。
- 本机未做真机运行验证。
