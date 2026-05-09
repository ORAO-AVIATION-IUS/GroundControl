#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "QMapLibre::Location" for configuration ""
set_property(TARGET QMapLibre::Location APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(QMapLibre::Location PROPERTIES
  IMPORTED_LINK_DEPENDENT_LIBRARIES_NOCONFIG "Qt6::OpenGL;Qt6::Network"
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libQMapLibreLocation.so.3.0.0"
  IMPORTED_SONAME_NOCONFIG "libQMapLibreLocation.so.3"
  )

list(APPEND _cmake_import_check_targets QMapLibre::Location )
list(APPEND _cmake_import_check_files_for_QMapLibre::Location "${_IMPORT_PREFIX}/lib/libQMapLibreLocation.so.3.0.0" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
