# BUILD_STATUS — 2026-09-07

## Crash cause (conclusion)
Prior flash-crash on iPhone 5c iOS7 most likely from combo of:
1) Heavy native launch (Auth/API/NSURLSession/AV) before first frame
2) Code signature using SHA256 as primary hash (iOS7 prefers SHA1)
3) Info.plist noise (NSAppTransportSecurity, UIBackgroundModes)
4) Linux Theos + iPhoneOS9.3.sdk only (no cleaner 7.1/8.4 SDK available from theos/sdks)

## Fix shipped
- Full app = UIWebView shell only (UIKit/Foundation/CoreGraphics), defer load to next runloop
- ldid fake-sign SHA1-only + get-task-allow
- Info.plist: MinimumOSVersion 7.0, CFBundleSupportedPlatforms=iPhoneOS, no ATS/background
- Official icons kept

## Artifacts
- Smoke: `/workspace/XYZSmoke-i4tools.ipa`
- Full (identical bytes): `/workspace/Xiaoyuzhou-爱思助手.ipa` = `/workspace/Xiaoyuzhou-i4tools.ipa` = `/workspace/xiaoyuzhou-ios7/dist/XiaoyuzhouLegacy-unsigned.ipa`

## Install (爱思助手)
1. Device jailbroken iOS7 + AppSync Unified
2. Import IPA in 爱思助手 → install
3. Test smoke first if full still dies: XYZSmoke should show white screen + "OK"
