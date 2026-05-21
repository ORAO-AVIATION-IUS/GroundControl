file(GLOB_RECURSE SOURCES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS "*.cpp" "*.h")
file(GLOB_RECURSE QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS "*.qml")

qt_add_library(AgcStyle STATIC)

set_source_files_properties(Style.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(AgcStyle
    URI Agc.Style
    SOURCES ${SOURCES}
    QML_FILES ${QML_FILES}
    IMPORT_PATH "${CMAKE_BINARY_DIR}"
)

target_link_libraries(AgcStyle PUBLIC Qt6::Quick Qt6::Svg)
target_compile_definitions(AgcStyle PRIVATE
    AGC_BREEZE_ICON_ROOT="${CMAKE_SOURCE_DIR}/third_party/breeze-icons/icons"
)
if(KF6BreezeIcons_FOUND)
    target_link_libraries(AgcStyle PUBLIC KF6::BreezeIcons)
    target_compile_definitions(AgcStyle PRIVATE AGC_HAS_KF6_BREEZE_ICONS=1)
endif()
target_include_directories(AgcStyleplugin INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
