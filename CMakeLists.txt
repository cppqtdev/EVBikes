cmake_minimum_required(VERSION 3.21.1)

project(EVBikes VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

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
    src/backend/VehicleData.cpp
    src/backend/NavigationData.cpp
    src/backend/PhoneData.cpp
    src/backend/SystemData.cpp
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

qul_add_target(EVBikes
    ${EVB_MAIN}
    ${EVB_CORE_SOURCES}
    ${EVB_BACKEND_SOURCES}
    ${EVB_PLATFORM_SOURCES}
    QML_PROJECT EVBikes.qmlproject
)

target_include_directories(EVBikes PRIVATE
    src
    qml/backend
)

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(EVBikes PRIVATE -Wall -Wextra)
endif()

app_target_setup_os(EVBikes)
