THEOS ?= /home/box/theos
TARGET := iphone:clang:9.3:7.0
ARCHS := armv7
include $(THEOS)/makefiles/common.mk
APPLICATION_NAME = XYZSmoke
XYZSmoke_FILES = Sources/main.m Sources/AppDelegate.m
XYZSmoke_FRAMEWORKS = UIKit Foundation CoreGraphics
XYZSmoke_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
XYZSmoke_LDFLAGS = -Wl,-undefined,error
XYZSmoke_CODESIGN_FLAGS = -Sent.plist -Hsha1
XYZSmoke_RESOURCE_DIRS = Resources
include $(THEOS_MAKE_PATH)/application.mk
