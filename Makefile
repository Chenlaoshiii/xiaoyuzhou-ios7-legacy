THEOS ?= /home/box/theos
TARGET := iphone:clang:9.3:7.0
ARCHS := armv7
include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = XiaoyuzhouLegacy
XiaoyuzhouLegacy_FILES = Sources/main.m Sources/AppDelegate.m Sources/compat_memset.c
XiaoyuzhouLegacy_FRAMEWORKS = UIKit Foundation CoreGraphics
XiaoyuzhouLegacy_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-parameter
XiaoyuzhouLegacy_LDFLAGS = -Wl,-undefined,error
XiaoyuzhouLegacy_CODESIGN_FLAGS = -Sent.plist -Hsha1
XiaoyuzhouLegacy_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/application.mk
