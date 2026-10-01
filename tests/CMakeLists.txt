cmake_minimum_required(VERSION 3.21)
project(EVBikesCoreTests LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(core_tests
    test_core.cpp
    ../src/core/can/VehicleCanDecoder.cpp
    ../src/core/nav/PhoneLinkProtocol.cpp
    ../src/core/alerts/AlertEvaluator.cpp
)
target_compile_options(core_tests PRIVATE -Wall -Wextra -Wpedantic -Werror -fsanitize=address,undefined)
target_link_options(core_tests PRIVATE -fsanitize=address,undefined)

enable_testing()
add_test(NAME core_tests COMMAND core_tests)

add_executable(backend_smoke
    backend_smoke.cpp
    ../src/core/can/VehicleCanDecoder.cpp
    ../src/core/nav/PhoneLinkProtocol.cpp
    ../src/core/alerts/AlertEvaluator.cpp
    ../src/backend/Backend.cpp
    ../src/backend/VehicleData.cpp
    ../src/backend/NavigationData.cpp
    ../src/backend/PhoneData.cpp
    ../src/backend/PhoneListData.cpp
    ../src/backend/SystemData.cpp
    ../src/backend/TripData.cpp
    ../src/backend/AlertData.cpp
    ../src/backend/ClusterInput.cpp
    ../src/backend/Simulator.cpp
    ../src/platform/sim/PlatformSim.cpp
)
target_include_directories(backend_smoke PRIVATE ../desktop/qul_shim ../qml/backend)
target_compile_options(backend_smoke PRIVATE -Wall -Wextra -Werror -fsanitize=address,undefined)
target_link_options(backend_smoke PRIVATE -fsanitize=address,undefined)
add_test(NAME backend_smoke COMMAND backend_smoke)
