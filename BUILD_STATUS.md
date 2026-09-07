# BUILD_STATUS — 2026-09-08 (UTC+8)

## This build: FULL NATIVE (no UIWebView)

Binary-search on iPhone 5c iOS 7 showed:
- XYZSmoke OK
- Xiaoyuzhou-nweb (icons, no UIWebView) OK
- Xiaoyuzhou with UIWebView+HTTPS CRASHES

**Conclusion:** UIWebView/network-at-launch path is toxic. This IPA restores the native podcast client **without UIWebView**.

### Launch path (matches nweb for first frame)
1. White window +「小宇宙」label + `makeKeyAndVisible`
2. Next main-queue turn: Login or TabBar from credentials
3. Token refresh / NSURLSession deferred further (lazy session in API + ImageCache)

### Player
AVFoundation/MediaPlayer **not linked**. `XYZPlayerManager` stubs play with alert「播放稍后」until CFNetwork/list UI is confirmed stable.

### Frameworks linked
UIKit, Foundation, CoreGraphics, QuartzCore, CFNetwork, Security, SystemConfiguration  
(+ libobjc, CoreFoundation, libSystem)

### Artifacts
| IPA | Role |
|-----|------|
| `/workspace/Xiaoyuzhou-i4tools.ipa` | native full client |
| `/workspace/Xiaoyuzhou-爱思助手.ipa` | identical |
| `/workspace/Xiaoyuzhou-native-i4tools.ipa` | identical |
| `/workspace/Xiaoyuzhou-nweb-i4tools.ipa` | prior no-web splash (kept) |
| `/workspace/Xiaoyuzhou-localhtml-i4tools.ipa` | prior localhtml UIWebView test (kept) |

### Build flags
`THEOS=/home/box/theos` · `TARGET=iphone:clang:9.3:7.0` · `ARCHS=armv7` · `FINALPACKAGE=1` · `ldid -Sent.plist -Hsha1` · entitlements: `get-task-allow` only · no iTunesArtwork
