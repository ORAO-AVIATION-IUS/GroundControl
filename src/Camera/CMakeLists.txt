file(GLOB_RECURSE SOURCES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS "*.cpp" "*.h")
file(GLOB_RECURSE QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS "*.qml")

# GStreamer discovery: PkgConfig on Unix, CMake find_package on Windows.
# On Windows, locate GStreamer's own pkg-config and restrict the search path
# so that unrelated pkg-config installations (e.g. conda) don't interfere.
if(WIN32)
    if(DEFINED ENV{GSTREAMER_1_0_ROOT_MSVC_X86_64})
        set(_gst_root "$ENV{GSTREAMER_1_0_ROOT_MSVC_X86_64}")
    else()
        set(_gst_root "C:/Program Files/gstreamer/1.0/msvc_x86_64")
    endif()
    if(EXISTS "${_gst_root}")
        set(PKG_CONFIG_EXECUTABLE "${_gst_root}/bin/pkg-config.exe" CACHE FILEPATH "" FORCE)
        set(ENV{PKG_CONFIG_LIBDIR} "${_gst_root}/lib/pkgconfig")
        set(ENV{PKG_CONFIG_PATH} "")
        list(PREPEND CMAKE_PREFIX_PATH "${_gst_root}")
    endif()
    find_package(GStreamer 1.0 REQUIRED COMPONENTS Core App Video)
else()
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(GST REQUIRED IMPORTED_TARGET
        gstreamer-1.0
        gstreamer-app-1.0
        gstreamer-video-1.0
    )
endif()

qt_add_library(AgcCamera STATIC)

if(WIN32)
    target_link_libraries(AgcCamera
        PUBLIC Qt6::Multimedia
        PRIVATE GStreamer::Core GStreamer::App GStreamer::Video
    )
else()
    target_link_libraries(AgcCamera
        PUBLIC Qt6::Multimedia
        PRIVATE PkgConfig::GST
    )
endif()

qt_add_qml_module(AgcCamera
    URI Agc.Camera
    SOURCES ${SOURCES}
    QML_FILES ${QML_FILES}
    IMPORT_PATH "${CMAKE_BINARY_DIR}"
)
