cmake_minimum_required(VERSION 3.22)
project(GroundControl VERSION 0.0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_INCLUDE_CURRENT_DIRS ON)

set(KDDockWidgets_FRONTENDS "qtquick" CACHE STRING "" FORCE)
set(KDDockWidgets_QML_MODULE ON CACHE BOOL "" FORCE)

configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/.qmlls.ini.in
    ${CMAKE_CURRENT_SOURCE_DIR}/.qmlls.ini
    @ONLY
)

find_package(Qt6 6.10 COMPONENTS Quick QuickControls2 Multimedia Location Positioning Svg REQUIRED)
find_package(KF6BreezeIcons QUIET)

# Prefer the per-platform prebuilt QMapLibre tree committed under third_party/.
# This keeps the project reproducible without a system-wide install.
#
# Linux has two prebuilts, because QMapLibre links against Qt private APIs
# (so it only works with the exact Qt minor version it was built with) and
# against the build machine's glibc:
#   linux         - Arch-style rolling distro: glibc >= 2.43, Qt 6.11.x
#   linux-ubuntu  - Ubuntu/Debian: glibc >= 2.35 (Ubuntu 22.04+), Qt 6.10.x,
#                   ICU bundled. Rebuild with `just bootstrap-maplibre`.
# AGC_QMAPLIBRE_PREBUILT picks one: auto (default, detected from
# /etc/os-release), linux, linux-ubuntu, or none (use a system QMapLibre).
set(AGC_QMAPLIBRE_PREBUILT "auto" CACHE STRING
    "QMapLibre prebuilt under third_party/maplibre-prebuilt (auto|linux|linux-ubuntu|none)")
set_property(CACHE AGC_QMAPLIBRE_PREBUILT PROPERTY STRINGS auto linux linux-ubuntu none)

set(_qmaplibre_flavor "${AGC_QMAPLIBRE_PREBUILT}")
if(_qmaplibre_flavor STREQUAL "auto")
    if(APPLE)
        set(_qmaplibre_flavor "macos")
    elseif(WIN32)
        set(_qmaplibre_flavor "windows")
    else()
        set(_qmaplibre_flavor "linux")
        if(EXISTS "/etc/os-release")
            file(STRINGS "/etc/os-release" _os_release REGEX "^(ID|ID_LIKE)=")
            if(_os_release MATCHES "ubuntu|debian")
                set(_qmaplibre_flavor "linux-ubuntu")
            endif()
        endif()
    endif()
endif()

if(NOT _qmaplibre_flavor STREQUAL "none")
    set(_qmaplibre_prebuilt "${CMAKE_CURRENT_SOURCE_DIR}/third_party/maplibre-prebuilt/${_qmaplibre_flavor}")
    if(NOT EXISTS "${_qmaplibre_prebuilt}")
        message(FATAL_ERROR "QMapLibre prebuilt not found: ${_qmaplibre_prebuilt}")
    endif()
    if(_qmaplibre_flavor STREQUAL "linux-ubuntu" AND NOT Qt6_VERSION MATCHES "^6\\.10\\.")
        message(FATAL_ERROR
            "The linux-ubuntu QMapLibre prebuilt requires Qt 6.10.x (found ${Qt6_VERSION}).\n"
            "Install it with aqtinstall (see README, \"Ubuntu / Debian\") and pass\n"
            "CMAKE_PREFIX_PATH=<qt>/6.10.x/gcc_64, or rebuild the prebuilt with\n"
            "`just bootstrap-maplibre` for your Qt version.")
    endif()
    message(STATUS "Using QMapLibre prebuilt: ${_qmaplibre_flavor}")
    list(PREPEND CMAKE_PREFIX_PATH "${_qmaplibre_prebuilt}")
    set(QMAPLIBRE_RUNTIME_ROOT "${_qmaplibre_prebuilt}")
endif()
find_package(QMapLibre REQUIRED COMPONENTS Location)

qt_standard_project_setup(REQUIRES 6.10)

set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml)

set(BUILD_MAVSDK_SERVER OFF CACHE BOOL "" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(BUILD_FUZZ_TESTS OFF CACHE BOOL "" FORCE)
set(MAVLINK_DIALECT "ardupilotmega" CACHE STRING "" FORCE)

if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/MAVSDK/cpp/CMakeLists.txt"
   OR NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/MAVSDK/proto/protos/mavsdk_options.proto")
    message(FATAL_ERROR
        "MAVSDK submodules are missing. Clone GroundControl with --recursive as documented."
    )
endif()

add_subdirectory(third_party/MAVSDK/cpp)

add_subdirectory(third_party/KDDockWidgets EXCLUDE_FROM_ALL)

file(GLOB_RECURSE QML_ASSETS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS
    resources/*.svg
    resources/*.png
    resources/*.json
    resources/*.qml
)

qt_add_executable(GroundControl
    src/main.cpp
    src/DarkViewFactory.h
    src/DarkViewFactory.cpp
)

file(GLOB ROOT_QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS "src/App/*.qml")
qt_add_qml_module(GroundControl
    URI Agc
    QML_FILES ${ROOT_QML_FILES}
)

add_subdirectory(src/Style)
add_subdirectory(src/Log)
add_subdirectory(src/Components)
add_subdirectory(src/Mavlink)
add_subdirectory(src/Panels)
add_subdirectory(src/Network)
add_subdirectory(src/Detection)
add_subdirectory(src/Camera)

qt_add_resources(GroundControl
    PREFIX "/"
    FILES ${QML_ASSETS}
)

target_link_libraries(GroundControl PRIVATE
	Qt6::Quick
	Qt6::QuickControls2
	Qt6::Location
	Qt6::Positioning
	Qt6::Multimedia
	KDAB::kddockwidgets
	AgcStyleplugin
	AgcLog
	AgcLogplugin
	AgcComponentsplugin
	AgcPanelsplugin
	AgcNetworkplugin
	AgcMavlinkplugin
	AgcDetectionplugin
	AgcCameraplugin
)

# Point the runtime linker at the prebuilt lib/ directory so that
# QMapLibre shared libraries and Qt plugins are resolved correctly.
if(DEFINED QMAPLIBRE_RUNTIME_ROOT)
    set_target_properties(GroundControl PROPERTIES
        BUILD_RPATH "${QMAPLIBRE_RUNTIME_ROOT}/lib"
        INSTALL_RPATH "${QMAPLIBRE_RUNTIME_ROOT}/lib"
    )
endif()

# Runtime environment for `just run` on Linux: the selected QMapLibre prebuilt
# plus the Qt lib dir (needed when Qt is not installed system-wide, e.g. aqt).
if(UNIX AND NOT APPLE AND DEFINED QMAPLIBRE_RUNTIME_ROOT)
    file(CONFIGURE OUTPUT "${CMAKE_BINARY_DIR}/runtime-env.sh" CONTENT [=[
# Generated by CMake. Sourced by `just run`.
export LD_LIBRARY_PATH="@QMAPLIBRE_RUNTIME_ROOT@/lib:@QT6_INSTALL_PREFIX@/@QT6_INSTALL_LIBS@${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="@QMAPLIBRE_RUNTIME_ROOT@/plugins"
export QML_IMPORT_PATH="@QMAPLIBRE_RUNTIME_ROOT@/qml"
]=] @ONLY)
endif()
