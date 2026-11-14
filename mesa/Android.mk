#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Mesa, the GPU driver (freedreno), from the Linaro vendor package. The package's own
# mesa_prebuilt/Android.mk defines these modules only for Linaro's devices (db845c, sm8x50),
# and the build drops a missing module of PRODUCT_PACKAGES without an error: without this
# file the image has no GPU driver. The module definitions are the package's, unchanged.

ifeq ($(TARGET_DEVICE),sdv_media_db845c)
ifeq ($(BOARD_USE_CUSTOMIZED_MESA),true)

ifeq ($(EXPECTED_LINARO_VENDOR_VERSION),)
$(error EXPECTED_LINARO_VENDOR_VERSION is not set (device/linaro/dragonboard/vendor-package-ver.mk))
endif
LOCAL_PATH := vendor/linaro/shared/$(EXPECTED_LINARO_VENDOR_VERSION)/mesa_prebuilt

include $(CLEAR_VARS)
LOCAL_MODULE := libEGL_mesa
LOCAL_MODULE_RELATIVE_PATH := egl
LOCAL_LICENSE_KINDS := SPDX-license-identifier-MIT
LOCAL_LICENSE_CONDITIONS := notice
LOCAL_NOTICE_FILE := $(LOCAL_PATH)/LICENSE
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_VENDOR_MODULE := true
LOCAL_STRIP_MODULE := false
LOCAL_SRC_FILES_arm := lib/$(LOCAL_MODULE_RELATIVE_PATH)/$(LOCAL_MODULE).so
LOCAL_SRC_FILES_arm64 := lib64/$(LOCAL_MODULE_RELATIVE_PATH)/$(LOCAL_MODULE).so
LOCAL_MODULE_PATH_32 := $(TARGET_OUT_VENDOR)/lib/
LOCAL_MODULE_PATH_64 := $(TARGET_OUT_VENDOR)/lib64/
LOCAL_CHECK_ELF_FILES := false
LOCAL_MODULE_SUFFIX := .so
LOCAL_MULTILIB := both
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := libGLESv2_mesa
LOCAL_MODULE_RELATIVE_PATH := egl
LOCAL_LICENSE_KINDS := SPDX-license-identifier-MIT
LOCAL_LICENSE_CONDITIONS := notice
LOCAL_NOTICE_FILE := $(LOCAL_PATH)/LICENSE
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_VENDOR_MODULE := true
LOCAL_STRIP_MODULE := false
LOCAL_SRC_FILES_arm := lib/$(LOCAL_MODULE_RELATIVE_PATH)/$(LOCAL_MODULE).so
LOCAL_SRC_FILES_arm64 := lib64/$(LOCAL_MODULE_RELATIVE_PATH)/$(LOCAL_MODULE).so
LOCAL_MODULE_PATH_32 := $(TARGET_OUT_VENDOR)/lib/
LOCAL_MODULE_PATH_64 := $(TARGET_OUT_VENDOR)/lib64/
LOCAL_CHECK_ELF_FILES := false
LOCAL_MODULE_SUFFIX := .so
LOCAL_MULTILIB := both
include $(BUILD_PREBUILT)


include $(CLEAR_VARS)
LOCAL_MODULE := libGLESv1_CM_mesa
LOCAL_MODULE_RELATIVE_PATH := egl
LOCAL_LICENSE_KINDS := SPDX-license-identifier-MIT
LOCAL_LICENSE_CONDITIONS := notice
LOCAL_NOTICE_FILE := $(LOCAL_PATH)/LICENSE
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_VENDOR_MODULE := true
LOCAL_STRIP_MODULE := false
LOCAL_SRC_FILES_arm := lib/$(LOCAL_MODULE_RELATIVE_PATH)/$(LOCAL_MODULE).so
LOCAL_SRC_FILES_arm64 := lib64/$(LOCAL_MODULE_RELATIVE_PATH)/$(LOCAL_MODULE).so
LOCAL_MODULE_PATH_32 := $(TARGET_OUT_VENDOR)/lib/
LOCAL_MODULE_PATH_64 := $(TARGET_OUT_VENDOR)/lib64/
LOCAL_CHECK_ELF_FILES := false
LOCAL_MODULE_SUFFIX := .so
LOCAL_MULTILIB := both
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := libgallium_dri
LOCAL_MODULE_RELATIVE_PATH :=
LOCAL_LICENSE_KINDS := SPDX-license-identifier-MIT
LOCAL_LICENSE_CONDITIONS := notice
LOCAL_NOTICE_FILE := $(LOCAL_PATH)/LICENSE
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_VENDOR_MODULE := true
LOCAL_STRIP_MODULE := false
LOCAL_SRC_FILES_arm := lib/$(LOCAL_MODULE_RELATIVE_PATH)/$(LOCAL_MODULE).so
LOCAL_SRC_FILES_arm64 := lib64/$(LOCAL_MODULE_RELATIVE_PATH)/$(LOCAL_MODULE).so
LOCAL_MODULE_PATH_32 := $(TARGET_OUT_VENDOR)/lib/
LOCAL_MODULE_PATH_64 := $(TARGET_OUT_VENDOR)/lib64/
LOCAL_CHECK_ELF_FILES := false
LOCAL_MODULE_SUFFIX := .so
LOCAL_MULTILIB := both
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := vulkan.freedreno
LOCAL_MODULE_RELATIVE_PATH := hw
LOCAL_LICENSE_KINDS := SPDX-license-identifier-MIT
LOCAL_LICENSE_CONDITIONS := notice
LOCAL_NOTICE_FILE := $(LOCAL_PATH)/LICENSE
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_VENDOR_MODULE := true
LOCAL_STRIP_MODULE := false
LOCAL_SRC_FILES_arm := lib/$(LOCAL_MODULE_RELATIVE_PATH)/$(LOCAL_MODULE).so
LOCAL_SRC_FILES_arm64 := lib64/$(LOCAL_MODULE_RELATIVE_PATH)/$(LOCAL_MODULE).so
LOCAL_MODULE_PATH_32 := $(TARGET_OUT_VENDOR)/lib/
LOCAL_MODULE_PATH_64 := $(TARGET_OUT_VENDOR)/lib64/
LOCAL_CHECK_ELF_FILES := false
LOCAL_MODULE_SUFFIX := .so
LOCAL_MULTILIB := both
include $(BUILD_PREBUILT)

endif
endif
