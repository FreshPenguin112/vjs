cmake_minimum_required(VERSION 3.16)

project(quickjs LANGUAGES C)

# =========================
# FLAGS
# =========================

set(qjs_cflags -Wall -D_GNU_SOURCE)

if(CMAKE_C_COMPILER_ID MATCHES "AppleClang|Clang")
  list(APPEND qjs_cflags
    -Wextra
    -Wno-sign-compare
    -Wno-missing-field-initializers
    -Wno-unused-parameter
    -Wno-unused-variable
    -funsigned-char)
else()
  list(APPEND qjs_cflags
    -Wno-array-bounds
    -Wno-unused-variable
    -Wno-unused-but-set-variable)
endif()

# =========================
# VERSION
# =========================
file(READ quickjs/VERSION QJS_VERSION_STR)
string(REGEX REPLACE "\n$" "" QJS_VERSION_STR "${QJS_VERSION_STR}")

message(STATUS
"QuickJS build:
  System:   ${CMAKE_SYSTEM_NAME}
  Compiler: ${CMAKE_C_COMPILER}
")

# =========================
# LIBRARY ONLY (NO TOOLS)
# =========================
add_library(qjs STATIC
  quickjs/cutils.c
  quickjs/libbf.c
  quickjs/libregexp.c
  quickjs/libunicode.c
  quickjs/quickjs.c
  quickjs/quickjs-libc.c
)

# =========================
# CORE PROPERTIES
# =========================
set_target_properties(qjs PROPERTIES
  C_STANDARD 11
  C_STANDARD_REQUIRED ON
  POSITION_INDEPENDENT_CODE ON
  ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)

target_compile_options(qjs PRIVATE ${qjs_cflags})

target_compile_definitions(qjs PUBLIC
  QJS_VERSION_STR="${QJS_VERSION_STR}"
  CONFIG_BIGNUM
  CONFIG_VERSION="${QJS_VERSION_STR}"
)

if(CMAKE_BUILD_TYPE MATCHES Debug)
  target_compile_definitions(qjs PRIVATE DUMP_LEAKS)
endif()

target_include_directories(qjs PUBLIC include)
target_include_directories(qjs PRIVATE quickjs)

# =========================
# PLATFORM LIBS (FIXED)
# =========================

# Android (Bionic): NO pthread linking needed
if(ANDROID)
  target_link_libraries(qjs PRIVATE m dl)

# Desktop platforms
else()
  target_link_libraries(qjs PRIVATE m dl pthread)
endif()
