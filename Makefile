# Theos Makefile — 小宇宙 Legacy (unofficial) for jailbroken iOS 7
THEOS ?= /home/box/theos
TARGET := iphone:clang:9.3:7.0
ARCHS := armv7
include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = XiaoyuzhouLegacy
XiaoyuzhouLegacy_FILES = \
	Sources/main.m \
	Sources/AppDelegate.m \
	Sources/compat_memset.c \
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

XiaoyuzhouLegacy_FRAMEWORKS = UIKit Foundation AVFoundation Security SystemConfiguration MediaPlayer CoreGraphics QuartzCore
XiaoyuzhouLegacy_CFLAGS = -fobjc-arc -Wno-unused-parameter -Wno-deprecated-declarations -Wno-nonnull -Wno-unused-variable \
	-ISources -ISources/API -ISources/Models -ISources/Managers -ISources/Utils -ISources/Views -ISources/Controllers
# Do NOT use -undefined dynamic_lookup — it causes flash-crashes on real devices.
XiaoyuzhouLegacy_LDFLAGS = -Wl,-undefined,error
XiaoyuzhouLegacy_CODESIGN_FLAGS = -Sent.plist
XiaoyuzhouLegacy_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "uicache || true; killall -9 SpringBoard || true"
