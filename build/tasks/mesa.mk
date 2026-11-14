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

# The build drops a missing module of PRODUCT_PACKAGES without an error. Without these
# modules the image has no OpenGL ES and Vulkan driver, so their absence stops the build.
ifeq ($(TARGET_DEVICE),sdv_media_db845c)
SDV_MEDIA_DB845C_MESA_MISSING := $(strip $(foreach m, \
    libEGL_mesa libGLESv1_CM_mesa libGLESv2_mesa libgallium_dri vulkan.freedreno, \
    $(if $(ALL_MODULES.$(m).PATH),,$(m))))
ifneq ($(SDV_MEDIA_DB845C_MESA_MISSING),)
$(error no Mesa module $(SDV_MEDIA_DB845C_MESA_MISSING): mesa/Android.mk was not read, or BOARD_USE_CUSTOMIZED_MESA is not true)
endif
endif
