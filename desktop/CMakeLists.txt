# Qt 6 desktop build of the cluster (used when the Qt for MCUs SDK is not found).
# Same QML and the same C++ backend; Qul headers come from qul_shim/, the C++
# singletons are exposed through the generated bridge/QulQmlBridge.*

find_package(Qt6 6.5 REQUIRED COMPONENTS Gui Quick Qml)
qt_standard_project_setup(REQUIRES 6.5)

set(EVB_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/..)
set(EVB_QML_OUT ${CMAKE_BINARY_DIR}/qml)
set(QML_IMPORT_PATH ${EVB_QML_OUT} CACHE STRING "Qt Creator QML import path" FORCE)

# --- backend (unchanged MCU sources + desktop shims) -------------------------
qt_add_library(evb_backend STATIC
    ${EVB_ROOT}/src/core/can/VehicleCanDecoder.cpp
    ${EVB_ROOT}/src/core/nav/PhoneLinkProtocol.cpp
    ${EVB_ROOT}/src/core/alerts/AlertEvaluator.cpp
    ${EVB_ROOT}/src/backend/Backend.cpp
    ${EVB_ROOT}/src/backend/VehicleData.cpp
    ${EVB_ROOT}/src/backend/NavigationData.cpp
    ${EVB_ROOT}/src/backend/PhoneData.cpp
    ${EVB_ROOT}/src/backend/SystemData.cpp
    ${EVB_ROOT}/src/backend/AlertData.cpp
    ${EVB_ROOT}/src/backend/ClusterInput.cpp
    ${EVB_ROOT}/src/backend/Simulator.cpp
    ${EVB_ROOT}/src/platform/sim/PlatformSim.cpp
)
target_include_directories(evb_backend PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/qul_shim
    ${EVB_ROOT}/qml/backend
    ${EVB_ROOT}/src
)
target_compile_features(evb_backend PUBLIC cxx_std_17)
set_target_properties(evb_backend PROPERTIES AUTOMOC OFF)

# --- QML module: ClusterBackend (generated QObject singletons) ---------------
qt_add_library(cluster_backend STATIC)
qt_add_qml_module(cluster_backend
    URI ClusterBackend
    VERSION 1.0
    OUTPUT_DIRECTORY ${EVB_QML_OUT}/ClusterBackend
    SOURCES bridge/QulQmlBridge.h bridge/QulQmlBridge.cpp
)
target_include_directories(cluster_backend PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/bridge)
target_link_libraries(cluster_backend PRIVATE Qt6::Qml evb_backend)

# --- QML module: QtQuickUltralite.Extras (ColorizedImage) ---------------------
qt_add_library(qul_extras STATIC)
qt_add_qml_module(qul_extras
    URI QtQuickUltralite.Extras
    VERSION 1.0
    OUTPUT_DIRECTORY ${EVB_QML_OUT}/QtQuickUltralite/Extras
    SOURCES extras/ColorizedImage.h extras/ColorizedImage.cpp
)
target_include_directories(qul_extras PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/extras)
target_link_libraries(qul_extras PRIVATE Qt6::Quick)

# --- QML modules from qml/ ----------------------------------------------------
add_subdirectory(${EVB_ROOT}/qml/core ${CMAKE_CURRENT_BINARY_DIR}/qml_core)
add_subdirectory(${EVB_ROOT}/qml/components ${CMAKE_CURRENT_BINARY_DIR}/qml_components)
add_subdirectory(${EVB_ROOT}/qml/screens ${CMAKE_CURRENT_BINARY_DIR}/qml_screens)

# --- application ---------------------------------------------------------------
qt_add_executable(EVBikes main.cpp)

set_source_files_properties(${EVB_ROOT}/qml/Main.qml PROPERTIES QT_RESOURCE_ALIAS Main.qml)
qt_add_qml_module(EVBikes
    URI EVBikesApp
    VERSION 1.0
    OUTPUT_DIRECTORY ${EVB_QML_OUT}/EVBikesApp
    QML_FILES ${EVB_ROOT}/qml/Main.qml
)

file(GLOB_RECURSE EVB_ASSETS CONFIGURE_DEPENDS RELATIVE ${EVB_ROOT}
    ${EVB_ROOT}/assets/icons/*.png
    ${EVB_ROOT}/assets/turns/*.png
    ${EVB_ROOT}/assets/images/*.png
    ${EVB_ROOT}/assets/cluster/*.png
    ${EVB_ROOT}/assets/fonts/*.ttf
)
list(TRANSFORM EVB_ASSETS PREPEND ${EVB_ROOT}/)
qt_add_resources(EVBikes "evb_assets"
    PREFIX "/"
    BASE ${EVB_ROOT}
    FILES ${EVB_ASSETS}
)

target_link_libraries(EVBikes PRIVATE
    Qt6::Gui
    Qt6::Quick
    evb_backend
    cluster_backend cluster_backendplugin
    qul_extras qul_extrasplugin
    cluster_core cluster_coreplugin
    cluster_components cluster_componentsplugin
    cluster_screens cluster_screensplugin
)

set_target_properties(EVBikes PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)
