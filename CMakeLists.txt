cmake_minimum_required(VERSION 3.16)
project(GroundControl VERSION 0.0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
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

find_package(Qt6 6.10 COMPONENTS Quick QuickControls2 Multimedia Location Positioning REQUIRED)
find_package(MAVSDK REQUIRED)
find_package(KF6BreezeIcons REQUIRED)

# Prefer the per-platform prebuilt QMapLibre tree committed under third_party/.
# This keeps the project reproducible without a system-wide install.
if(APPLE)
    set(_qmaplibre_prebuilt "${CMAKE_CURRENT_SOURCE_DIR}/third_party/maplibre-prebuilt/macos")
elseif(WIN32)
    set(_qmaplibre_prebuilt "${CMAKE_CURRENT_SOURCE_DIR}/third_party/maplibre-prebuilt/windows")
else()
    set(_qmaplibre_prebuilt "${CMAKE_CURRENT_SOURCE_DIR}/third_party/maplibre-prebuilt/linux")
endif()
if(EXISTS "${_qmaplibre_prebuilt}")
    list(PREPEND CMAKE_PREFIX_PATH "${_qmaplibre_prebuilt}")
    set(QMAPLIBRE_RUNTIME_ROOT "${_qmaplibre_prebuilt}")
endif()
find_package(QMapLibre REQUIRED COMPONENTS Location)

qt_standard_project_setup(REQUIRES 6.10)

set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml)

add_subdirectory(third_party/KDDockWidgets EXCLUDE_FROM_ALL)

file(GLOB_RECURSE QML_ASSETS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS
    resources/*.svg
    resources/*.png
)

qt_add_executable(GroundControl
    src/main.cpp
)

file(GLOB ROOT_QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS "src/App/*.qml")
qt_add_qml_module(GroundControl
    URI Agc
    QML_FILES ${ROOT_QML_FILES}
)

add_subdirectory(src/Style)
add_subdirectory(src/Components)
add_subdirectory(src/Panels)
add_subdirectory(src/Network)
add_subdirectory(src/Mavlink)
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
	AgcComponentsplugin
	AgcPanelsplugin
	AgcNetworkplugin
	AgcMavlinkplugin
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
