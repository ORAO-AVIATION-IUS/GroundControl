cmake_minimum_required(VERSION 3.16)
project(GroundControl VERSION 0.0.1 LANGUAGES CXX)

include(FetchContent)
FetchContent_Declare(
    breeze-icons
    GIT_REPOSITORY https://invent.kde.org/frameworks/breeze-icons.git
    GIT_TAG        v6.12.0
)

FetchContent_GetProperties(breeze-icons)
if(NOT breeze-icons_POPULATED)
    FetchContent_Populate(breeze-icons)

    # v6.12.0 uses CMAKE_SOURCE_DIR in add_custom_command which resolves to the
    # top-level project root under FetchContent. Patch it to use the correct path.
    set(_lib_cmake "${breeze-icons_SOURCE_DIR}/src/lib/CMakeLists.txt")
    file(READ "${_lib_cmake}" _content)
    string(REPLACE "\${CMAKE_SOURCE_DIR}/icons"
                   "\${CMAKE_CURRENT_SOURCE_DIR}/../../icons" _content "${_content}")
    string(REPLACE "\${CMAKE_SOURCE_DIR}/icons-dark"
                   "\${CMAKE_CURRENT_SOURCE_DIR}/../../icons-dark" _content "${_content}")
    file(WRITE "${_lib_cmake}" "${_content}")

    set(SKIP_INSTALL_ALL ON CACHE BOOL "" FORCE)
    set(SKIP_INSTALL_ICONS ON CACHE BOOL "" FORCE)
    add_subdirectory("${breeze-icons_SOURCE_DIR}" "${breeze-icons_BINARY_DIR}" EXCLUDE_FROM_ALL)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_INCLUDE_CURRENT_DIRS ON)

set(KDDockWidgets_FRONTENDS "qtquick" CACHE STRING "" FORCE)

find_package(Qt6 6.10 COMPONENTS Quick QuickControls2 REQUIRED)

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

target_link_libraries(GroundControl PRIVATE Qt6::Quick Qt6::QuickControls2 KDAB::kddockwidgets KF6::BreezeIcons)
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