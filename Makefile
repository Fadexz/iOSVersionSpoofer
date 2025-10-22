//THEOS_DEVICE_IP = 127.0.0.1

ARCHS = arm64 arm64e

FINALPACKAGE = 1

TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = SpringBoard

TWEAK_NAME = OSVersionSpoofer
$(TWEAK_NAME)_FILES = Tweak.x
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation
$(TWEAK_NAME)_EXTRA_FRAMEWORKS = AltList

$(TWEAK_NAME)_CFLAGS = -fobjc-arc

SUBPROJECTS += OSVersionSpooferPrefs

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
