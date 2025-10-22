ARCHS = arm64 arm64e

#ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
#TARGET := iphone:clang:16.2:15.0
#else
TARGET := iphone:clang:13.5:7.0
#endif

BUNDLE_NAME = OSVersionSpooferPrefs

OSVersionSpooferPrefs_FILES = APPRootListController.m
OSVersionSpooferPrefs_FRAMEWORKS = UIKit
OSVersionSpooferPrefs_PRIVATE_FRAMEWORKS = Preferences
OSVersionSpooferPrefs_EXTRA_FRAMEWORKS = AltList
OSVersionSpooferPrefs_INSTALL_PATH = /Library/PreferenceBundles
OSVersionSpooferPrefs_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk