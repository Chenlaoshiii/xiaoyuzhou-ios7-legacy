# Theos Makefile — 小宇宙 Legacy native (no UIWebView) for jailbroken iOS 7
THEOS ?= /home/box/theos
TARGET := iphone:clang:9.3:7.0
ARCHS := armv7
include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = XiaoyuzhouLegacy
XiaoyuzhouLegacy_FILES = \
	Sources/main.m \
	Sources/AppDelegate.m \
	Sources/API/XYZAPIClient.m \
	Sources/Models/XYZModels.m \
	Sources/Managers/XYZAuthManager.m \
	Sources/Managers/XYZPlayerManager.m \
	Sources/Managers/XYZImageCache.m \
	Sources/Utils/XYZJSONHelper.m \
	Sources/Utils/XYZUIHelpers.m \
	Sources/Views/XYZPodcastCell.m \
	Sources/Views/XYZEpisodeCell.m \
	Sources/Views/XYZCommentCell.m \
	Sources/Views/XYZMiniPlayerView.m \
	Sources/Controllers/XYZLoginViewController.m \
	Sources/Controllers/XYZTabBarController.m \
	Sources/Controllers/XYZHomeViewController.m \
	Sources/Controllers/XYZSearchViewController.m \
	Sources/Controllers/XYZSubscriptionViewController.m \
	Sources/Controllers/XYZProfileViewController.m \
	Sources/Controllers/XYZPodcastDetailViewController.m \
	Sources/Controllers/XYZEpisodeDetailViewController.m \
	Sources/Controllers/XYZPlayerViewController.m

# No UIWebView. No AVFoundation/MediaPlayer this build (player stubbed).
# CFNetwork/Security for deferred NSURLSession HTTPS after first frame.
XiaoyuzhouLegacy_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore CFNetwork Security SystemConfiguration
XiaoyuzhouLegacy_CFLAGS = -fobjc-arc -Wno-unused-parameter -Wno-deprecated-declarations -Wno-nonnull -Wno-unused-variable \
	-ISources -ISources/API -ISources/Models -ISources/Managers -ISources/Utils -ISources/Views -ISources/Controllers
XiaoyuzhouLegacy_LDFLAGS = -Wl,-undefined,error
XiaoyuzhouLegacy_CODESIGN_FLAGS = -Sent.plist -Hsha1
XiaoyuzhouLegacy_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/application.mk
