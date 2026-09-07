# 小宇宙 Legacy（非官方）

面向 **越狱 iPhone 5c / iOS 7（armv7）** 的非官方 [小宇宙](https://www.xiaoyuzhoufm.com/) 播客客户端。

> **免责声明**：爱好者学习用途，**与小宇宙官方（行吟信息科技）无任何隶属或授权关系**。请勿用于冒充官方应用。使用风险自负；请尊重播客版权与平台服务条款。API 形状参考社区项目 [ultrazg/xyz](https://github.com/ultrazg/xyz) 的公开文档。

## 为什么做这个

现代 Xcode / Swift / SwiftUI / arm64 默认工程在 32 位 iOS 7 上经常「装得上、一点开就闪退」。本仓库按 **2013 年那套约束** 来写：

| 项 | 选择 |
| --- | --- |
| 语言 | 纯 Objective-C（无 Swift / SwiftUI） |
| UI | UIKit（`UIWindow` + `UIViewController`，无 Scene） |
| 架构 | **armv7**（无 arm64） |
| 部署目标 | **iOS 7.0** |
| 构建 | Theos application → `/Applications` 的 `.deb`，或未签名 IPA（AppSync / 爱思助手） |

## 当前真机策略（闪退对策）

点开秒退时，优先怀疑 **SHA256 签名 / 新 SDK 工具链**，而不是业务代码。本仓库现在默认打成：

1. **smoke/** — 白屏 + 文字 `OK`，只验证进程能起来  
2. **主 App** — 笨办法：`UIWebView` 加载 `https://www.xiaoyuzhoufm.com/`（失败则 http / 本地 HTML 兜底），先保证能看见界面

请先装 `XYZSmoke-i4tools.ipa`：能看到 OK 再装正式 IPA。

## 功能（目标）

- 短信验证码登录 + Token 刷新
- 首页发现、搜索、订阅 / 取消订阅
- 节目与单集详情（封面、简介、评论）
- AVPlayer 播放 + 迷你播放条
- 简体中文界面

> 真机若仍秒退，优先怀疑 **工具链 / SDK / 代码签名（SHA1 vs SHA256）** 与 iOS 7 dyld 不兼容，而不是业务逻辑。可用仓库旁的 smoke 空壳工程先验证「白屏能否站住」。

## 工程结构

```
xiaoyuzhou-ios7/
  Makefile              # Theos
  control / ent.plist / ipa-ent.plist
  Resources/            # Info.plist、图标
  Sources/              # API / Models / Managers / Controllers / Views
  layout/DEBIAN/        # postinst（ldid + uicache）
  scripts/build-deb.sh
  scripts/make-ipa-unsigned.sh
  BUILD_STATUS.md
```

- **Bundle ID**: `com.lars.xiaoyuzhoulegacy`
- **显示名**: 小宇宙

## 编译

需要 [Theos](https://theos.dev/) 与 **真机用 iPhoneOS SDK**（尽量用 7.x / 8.x 设备 SDK；仅含模拟器切片的 TBD 容易链出「能装不能开」的包）。

```bash
export THEOS=/path/to/theos
cd xiaoyuzhou-ios7
make clean
make package FINALPACKAGE=1
# 或
./scripts/build-deb.sh
./scripts/make-ipa-unsigned.sh
```

产物：

- `packages/*.deb` — 越狱装进 `/Applications`，一般无需七天重签
- `dist/*-unsigned.ipa` — 需 **AppSync Unified**（[Karen 源](https://cydia.akemi.ai/)），可用爱思助手 / Filza 安装

## 安装（爱思助手）

1. 越狱 iOS 7 设备安装 **AppSync Unified**
2. 电脑打开爱思助手 → 应用游戏 → 安装 IPA
3. 选择打包好的 IPA 传到手机

若图标亮一下即退：到 `/var/mobile/Library/Logs/CrashReporter/` 取崩溃日志，重点看架构、缺库、签名算法。

## 状态

详见 [`BUILD_STATUS.md`](./BUILD_STATUS.md)。登录与部分 JSON 字段需真机 live 验证；上游 API 可能变更。

## License

仅供个人学习与研究。图标若使用官方素材，版权归原权利人所有。
