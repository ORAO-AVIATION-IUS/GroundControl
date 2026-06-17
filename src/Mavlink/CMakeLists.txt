file(GLOB_RECURSE SOURCES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS "*.cpp" "*.h")
file(GLOB_RECURSE QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS "*.qml")
list(APPEND SOURCES MissionPlanModel.h MissionPlanModel.cpp)
list(REMOVE_DUPLICATES SOURCES)

qt_add_library(AgcMavlink STATIC)

qt_add_qml_module(AgcMavlink
    URI Agc.Mavlink
    SOURCES ${SOURCES}
    QML_FILES ${QML_FILES}
    IMPORT_PATH "${CMAKE_BINARY_DIR}"
)

target_link_libraries(AgcMavlink PRIVATE mavsdk AgcLog)
