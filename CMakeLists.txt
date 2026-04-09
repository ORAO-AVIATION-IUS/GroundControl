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

qt_standard_project_setup(REQUIRES 6.10)

add_subdirectory(third_party/KDDockWidgets EXCLUDE_FROM_ALL)

file(GLOB_RECURSE QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS
    src/*.qml
    src/theme/qmldir
    )
file(GLOB_RECURSE QML_ASSETS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS
    resources/*.svg
    resources/*.png
)

qt_add_executable(GroundControl
    src/main.cpp
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

target_link_libraries(GroundControl PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Location Qt6::Positioning QMapLibre::PluginQml KDAB::kddockwidgets)
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