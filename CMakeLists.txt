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
set(MAVLINK_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/c_library_v2") 
# Network modülü zaten ekli, Core eklendi
find_package(Qt6 6.10 COMPONENTS Core Network Quick QuickControls2 REQUIRED)

qt_standard_project_setup(REQUIRES 6.10)

add_subdirectory(third_party/KDDockWidgets EXCLUDE_FROM_ALL)

# Mavlink kütüphanesinin yolunu buraya ekledik
include_directories(
    ${CMAKE_SOURCE_DIR}/third_party/c_library_v2
    ${CMAKE_SOURCE_DIR}/src/MAVLinkManager # .h dosyasını bulması için
)

file(GLOB QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS
    qml/*.qml
)
file(GLOB QML_ASSETS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS
    assets/*.png
    assets/*.svg
)

# Buraya yeni C++ dosyalarını ekledik
qt_add_executable(GroundControl
    main.cpp
    src/MAVLinkManager/MAVLinkManager.cpp
    src/MAVLinkManager/MAVLinkManager.h
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

# Kütüphane bağlantıları (KDAB::kddockwidgets ve Qt6 modülleri)
target_link_libraries(GroundControl PRIVATE 
    Qt6::Core 
    Qt6::Network 
    Qt6::Quick 
    Qt6::QuickControls2 
    KDAB::kddockwidgets
)
target_include_directories(GroundControl PRIVATE 
    src/MAVLinkManager
    ${MAVLINK_INCLUDE_DIR}
)

#qt creator mavlink warning uyarıları silmek için eklend
target_compile_options(GroundControl PRIVATE
-Wno-address-of-packed-member
)
