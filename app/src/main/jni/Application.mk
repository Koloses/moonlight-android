# Application.mk for Moonlight

# Our minimum version is Android 5.0
APP_PLATFORM := android-21

# We support 16KB pages
APP_SUPPORT_FLEXIBLE_PAGE_SIZES := true

# The PyroWave decoder is C++20 (Vulkan + vulkan_raii). The rest of moonlight-core
# is C and unaffected. c++_shared provides the C++ standard library at runtime.
APP_STL := c++_shared
APP_CPPFLAGS := -std=c++20 -fexceptions -frtti
