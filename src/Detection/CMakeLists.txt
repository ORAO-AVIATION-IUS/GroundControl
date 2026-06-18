file(GLOB_RECURSE SOURCES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS "*.cpp" "*.h")
file(GLOB_RECURSE QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS "*.qml")

list(FILTER SOURCES EXCLUDE REGEX "^\\.venv/")
list(FILTER QML_FILES EXCLUDE REGEX "^\\.venv/")

qt_add_library(AgcDetection STATIC)

target_link_libraries(AgcDetection
    PUBLIC Qt6::Core
)

target_include_directories(AgcDetection
    PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
)

target_compile_definitions(AgcDetection
    PRIVATE AGC_DETECTION_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}"
)

qt_add_qml_module(AgcDetection
    URI Agc.Detection
    SOURCES ${SOURCES}
    QML_FILES ${QML_FILES}
    IMPORT_PATH "${CMAKE_BINARY_DIR}"
)

set(DETECTION_RUNTIME_DIR "${CMAKE_BINARY_DIR}/detection")
set(DETECTION_RUNTIME_OUTPUTS
    "${DETECTION_RUNTIME_DIR}/detector.py"
    "${DETECTION_RUNTIME_DIR}/pyproject.toml"
)

add_custom_command(
    OUTPUT ${DETECTION_RUNTIME_OUTPUTS}
    COMMAND ${CMAKE_COMMAND} -E make_directory "${DETECTION_RUNTIME_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/detector.py"
        "${DETECTION_RUNTIME_DIR}/detector.py"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/pyproject.toml"
        "${DETECTION_RUNTIME_DIR}/pyproject.toml"
    DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/detector.py"
        "${CMAKE_CURRENT_SOURCE_DIR}/pyproject.toml"
    COMMENT "Copying detection runtime files"
)

add_custom_target(AgcDetectionRuntime ALL
    DEPENDS ${DETECTION_RUNTIME_OUTPUTS}
)

add_dependencies(GroundControl AgcDetectionRuntime)
