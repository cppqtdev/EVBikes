cmake_minimum_required(VERSION 3.21.1)

# ASM is not optional: the exporter writes the image blobs into
# qulrcc_assets_s.S and the font glyphs into qul_font_files_loader.S, and
# without the assembler CMake drops both from the target without a word.
project(EVBikes VERSION 0.1.0 LANGUAGES C CXX ASM)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(EVB_SIZE_OPTIMIZED_RELEASE "Optimize GNU release builds for size" ON)
if(EVB_SIZE_OPTIMIZED_RELEASE AND CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    add_compile_options($<$<CONFIG:Release>:-Os> $<$<CONFIG:Release>:-ffunction-sections> $<$<CONFIG:Release>:-fdata-sections>)
    add_link_options($<$<CONFIG:Release>:-Wl,--gc-sections>)
endif()

option(EVB_BUILD_HOST_TESTS "Build host unit tests instead of the Qt for MCUs app" OFF)
if(EVB_BUILD_HOST_TESTS)
    enable_testing()
    add_subdirectory(tests)
    return()
endif()

# Qt for MCUs SDK present -> MCU build (desktop "Qt" platform or a board).
# Otherwise -> plain Qt 6 desktop build of the same UI (see desktop/).
if(NOT TARGET Qul::Core)
    find_package(Qul QUIET)
endif()

if(NOT Qul_FOUND AND NOT TARGET Qul::Core)
    message(STATUS "EVBikes: Qt for MCUs (Qul) not found, building the Qt 6 desktop version")
    add_subdirectory(desktop)
    return()
endif()

set(EVB_CORE_SOURCES
    src/core/can/VehicleCanDecoder.cpp
    src/core/nav/PhoneLinkProtocol.cpp
    src/core/alerts/AlertEvaluator.cpp
)

set(EVB_BACKEND_SOURCES
    src/backend/Backend.cpp
    src/backend/ConnectivityData.cpp
    src/backend/VehicleData.cpp
    src/backend/NavigationData.cpp
    src/backend/PhoneData.cpp
    src/backend/PhoneListData.cpp
    src/backend/SystemData.cpp
    src/backend/TripData.cpp
    src/backend/AlertData.cpp
    src/backend/ClusterInput.cpp
    src/backend/Simulator.cpp
)

# Desktop backend is called "Qt" in Qt for MCUs.
string(TOLOWER "${QUL_PLATFORM}" EVB_PLATFORM_LOWER)
if(EVB_PLATFORM_LOWER STREQUAL "qt")
    set(EVB_PLATFORM_SOURCES src/platform/sim/PlatformSim.cpp)
else()
    set(EVB_PLATFORM_SOURCES src/platform/board/PlatformBoard.cpp)
endif()

if(QUL_OS STREQUAL "FreeRTOS")
    set(EVB_MAIN src/os/main_freertos.cpp)
else()
    set(EVB_MAIN src/main.cpp)
endif()

set(EVB_QML_PROJECT EVBikes.qmlproject)
if(EVB_PLATFORM_LOWER MATCHES "^tviic2d")
    # Qt's TRAVEO port builds at 32 bpp. Layer depths are configured separately.
    set(EVB_QML_PROJECT profiles/traveo/EVBikes.qmlproject)
endif()

qul_add_target(EVBikes
    ${EVB_MAIN}
    ${EVB_CORE_SOURCES}
    ${EVB_BACKEND_SOURCES}
    ${EVB_PLATFORM_SOURCES}
    QML_PROJECT ${EVB_QML_PROJECT}
)

target_compile_definitions(EVBikes PRIVATE EVB_QUL_RUNTIME=1)

target_include_directories(EVBikes PRIVATE
    src
    qml/backend
)

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(EVBikes PRIVATE -Wall -Wextra)
endif()

app_target_setup_os(EVBikes)

# Keep full debugging information beside the executable. GDB discovers it
# through .gnu_debuglink, so source stepping and variable inspection still work.
option(EVB_SEPARATE_DEBUG_SYMBOLS "Store Linux GNU Debug symbols in a compressed sidecar" ON)
if(EVB_SEPARATE_DEBUG_SYMBOLS AND CMAKE_SYSTEM_NAME STREQUAL "Linux"
   AND CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND CMAKE_OBJCOPY)
    set_property(TARGET EVBikes APPEND PROPERTY LINK_DEPENDS
        ${CMAKE_CURRENT_SOURCE_DIR}/cmake/SeparateDebugSymbols.cmake)
    add_custom_command(TARGET EVBikes POST_BUILD
        COMMAND ${CMAKE_COMMAND}
            "-DCONFIG=$<CONFIG>"
            "-DEXECUTABLE=$<TARGET_FILE:EVBikes>"
            "-DOBJCOPY=${CMAKE_OBJCOPY}"
            -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/SeparateDebugSymbols.cmake
        VERBATIM
        COMMENT "Keep Debug symbols in a compressed companion file")
endif()

# Strip only a distribution copy. Keep the linked executable for debugging.
if(CMAKE_STRIP AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
    add_custom_target(EVBikes-package
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/package
        COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:EVBikes> ${CMAKE_CURRENT_BINARY_DIR}/package/EVBikes
        COMMAND ${CMAKE_STRIP} --strip-unneeded ${CMAKE_CURRENT_BINARY_DIR}/package/EVBikes
        DEPENDS EVBikes
        COMMENT "Create a stripped distribution executable")
endif()
