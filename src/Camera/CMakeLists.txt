file(GLOB_RECURSE SOURCES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS "*.cpp" "*.h")
file(GLOB_RECURSE QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS "*.qml")

qt_add_library(AgcCamera STATIC)

target_link_libraries(AgcCamera PRIVATE
    Qt6::Multimedia
)

qt_add_qml_module(AgcCamera
    URI Agc.Camera
    SOURCES ${SOURCES}
    QML_FILES ${QML_FILES}
    IMPORT_PATH "${CMAKE_BINARY_DIR}"
)
