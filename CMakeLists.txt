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

find_package(Qt6 6.10 COMPONENTS Quick QuickControls2 Location Positioning REQUIRED)

find_package(QMapLibre REQUIRED COMPONENTS Location)

find_package(KF6BreezeIcons REQUIRED)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GST REQUIRED gstreamer-1.0 gstreamer-app-1.0 gstreamer-video-1.0)

qt_standard_project_setup(REQUIRES 6.10)

add_subdirectory(third_party/KDDockWidgets EXCLUDE_FROM_ALL)

set(QML_FILES
    src/AirspeedIndicator.qml
    src/AttitudeIndicator.qml
    src/ButtonTestPanel.qml
    src/CompassIndicator.qml
    src/CompassPanel.qml
    src/HeadingIndicator.qml
    src/LeftPanel.qml
    src/Main.qml
    src/MapView.qml
    src/RightPanel.qml
    src/TurnController.qml
    src/VideoStreamPanel.qml
    src/components/BatteryIndicator.qml
    src/components/Btn.qml
    src/components/IconButton.qml
    src/components/TelemetryBox.qml
    src/theme/Style.qml
    src/theme/qmldir
)

set(QML_ASSETS
    resources/assets/airspeed_background.svg
    resources/assets/airspeed_pointer.svg
    resources/assets/attitude_back.svg
    resources/assets/attitude_frame.svg
    resources/assets/attitude_pointer.svg
    resources/assets/attitude_triangle.svg
    resources/assets/compass_background.svg
    resources/assets/compass_needle.svg
    resources/assets/heading_background.svg
    resources/assets/heading_face.svg
    resources/assets/tc_airplane.svg
    resources/assets/tc_ball.svg
    resources/assets/tc_bezel.svg
    resources/assets/tc_glass.svg
    resources/assets/tc_inclinometer.svg
    resources/assets/tc_scale.svg
    resources/icons/Armed.svg
    resources/icons/Battery.svg
    resources/icons/BatteryCritical.svg
    resources/icons/BatteryEMERGENCY.svg
    resources/icons/BatteryGreen.svg
    resources/icons/BatteryOrange.svg
    resources/icons/BatteryYellow.svg
    resources/icons/Camera.svg
    resources/icons/Cancel.svg
    resources/icons/Edit.svg
    resources/icons/Settings.svg
    resources/icons/Sliders.svg
)

qt_add_executable(GroundControl
    src/main.cpp
    src/GStreamerVideoItem.h
    src/GStreamerVideoItem.cpp
)

qt_add_qml_module(GroundControl
    URI gc
    VERSION 1.0
)

qt_add_resources(GroundControl
    PREFIX "/"
    FILES ${QML_FILES}
    FILES ${QML_ASSETS}
)

target_link_libraries(GroundControl PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Location Qt6::Positioning QMapLibre::PluginQml KF6::BreezeIcons KDAB::kddockwidgets ${GST_LIBRARIES})
target_include_directories(GroundControl PRIVATE ${GST_INCLUDE_DIRS})
# set(KDDockWidgets_QT6 ON CACHE BOOL "" FORCE)
# set(KDDockWidgets_FRONTENDS "qtquick" CACHE STRING "" FORCE)
# set(KDDockWidgets_QML_MODULE ON CACHE BOOL "" FORCE)
# set(KDDockWidgets_EXAMPLES OFF CACHE BOOL "" FORCE)
# set(KDDockWidgets_TESTS OFF CACHE BOOL "" FORCE)

# add_subdirectory(third_party/KDDockWidgets EXCLUDE_FROM_ALL)

# add_executable(GroundControl
#     main.cpp
#     resources.qrc
# )

# target_link_libraries(GroundControl PRIVATE
#     Qt6::Quick
#     Qt6::QuickControls2
#     KDAB::kddockwidgets
# )