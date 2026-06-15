# Android.mk for the vendored PyroWave GPU wavelet decoder.
#
# Builds libpyrowave-decoder.so: the PyroWave Vulkan decode path + a native
# decoder that presents to an Android Surface via ANativeWindow (CPU readback,
# matching the desktop SDL approach - no Vulkan swapchain).
#
# REQUIRES (build time): the generated SPIR-V table at generated/pyrowave_shaders.cpp.
# It is produced by tools/generate_shaders.py (needs python3 + glslangValidator).
# The gradle task `generatePyrowaveShaders` runs it before the native build; see
# app/build.gradle. If you build ndk-build directly, run it manually first:
#   python3 tools/generate_shaders.py --shader-dir shaders --output-dir generated

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := pyrowave-decoder

LOCAL_SRC_FILES := \
    src/pyrowave/pyrowave_common.cpp \
    src/pyrowave/pyrowave_decoder.cpp \
    src/vk/allocation.cpp \
    src/vk/vk_allocator.cpp \
    src/vk/error_category.cpp \
    src/vk/vk_mem_alloc.cpp \
    generated/pyrowave_shaders.cpp \
    decoder/pyrowave_vk_android.cpp \
    decoder/pyrowave_android_decoder.cpp

LOCAL_C_INCLUDES := \
    $(LOCAL_PATH)/src \
    $(LOCAL_PATH)/src/pyrowave \
    $(LOCAL_PATH)/external \
    $(LOCAL_PATH)/generated \
    $(LOCAL_PATH)/decoder

# The Android NDK ships the Vulkan C headers (vulkan/vulkan.h) but NOT the C++
# bindings (vulkan/vulkan.hpp, vulkan/vulkan_raii.hpp) that the codec uses. Supply
# them one of two ways:
#   1. Copy your system Vulkan-Headers into external/ (they are on the include
#      path already), e.g. on Arch:
#        cp -r /usr/include/vulkan /usr/include/vk_video app/src/main/jni/pyrowave/external/
#   2. Pass a directory that contains vulkan/vulkan.hpp via the ndk-build variable
#      VULKAN_HEADERS_INCLUDE (wired from the gradle property -PvulkanHeaders=...).
ifneq ($(VULKAN_HEADERS_INCLUDE),)
LOCAL_C_INCLUDES += $(VULKAN_HEADERS_INCLUDE)
endif

LOCAL_CPPFLAGS := -std=c++20 -fexceptions -frtti \
    -DVULKAN_HPP_NO_STRUCT_CONSTRUCTORS \
    -DVMA_STATIC_VULKAN_FUNCTIONS=0 \
    -DVMA_DYNAMIC_VULKAN_FUNCTIONS=1 \
    -DVULKAN_HPP_TYPESAFE_CONVERSION=1 \
    -DVK_USE_PLATFORM_ANDROID_KHR=1

# Vulkan is loaded dynamically at runtime (vulkan_raii's DynamicLoader dlopen's
# libvulkan.so, VMA uses dynamic functions). This avoids linking -lvulkan, which
# is unavailable below API 24, so the app keeps minSdk 21 - PyroWave simply fails
# to initialize (and falls back) on devices without Vulkan.
# libandroid: ANativeWindow present; liblog: logging; libdl: dlopen.
LOCAL_LDLIBS := -landroid -llog -ldl

LOCAL_BRANCH_PROTECTION := standard

include $(BUILD_SHARED_LIBRARY)
