file(GLOB_RECURSE SOURCES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS "*.cpp" "*.h")
file(GLOB_RECURSE QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS "*.qml")

# GStreamer discovery: PkgConfig on Unix, CMake find_package on Windows
if(WIN32)
    find_package(GStreamer REQUIRED COMPONENTS gstreamer gstreamer-app gstreamer-video)
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
        PRIVATE GStreamer::gstreamer GStreamer::gstreamer-app GStreamer::gstreamer-video
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

# should maybe consider obfuscating the python side somehow
add_custom_command(TARGET AgcCamera POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/detector.py"
        "$<TARGET_FILE_DIR:GroundControl>/detector.py"
    COMMENT "Copying detector.py to build output"
)