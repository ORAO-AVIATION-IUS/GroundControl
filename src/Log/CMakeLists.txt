file(GLOB_RECURSE SOURCES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS "*.cpp" "*.h")
file(GLOB_RECURSE QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS "*.qml")

qt_add_library(AgcLog STATIC)

target_link_libraries(AgcLog
    PUBLIC Qt6::Core Qt6::Qml
)

target_include_directories(AgcLog PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

qt_add_qml_module(AgcLog
    URI Agc.Log
    SOURCES ${SOURCES}
    QML_FILES ${QML_FILES}
    IMPORT_PATH "${CMAKE_BINARY_DIR}"
)
