#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "QMapLibre::Location" for configuration "Release"
set_property(TARGET QMapLibre::Location APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(QMapLibre::Location PROPERTIES
  IMPORTED_LINK_DEPENDENT_LIBRARIES_RELEASE "QMapLibre::QuickPrivate;Qt6::Network"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libQMapLibreLocation.so.4.0.0"
  IMPORTED_SONAME_RELEASE "libQMapLibreLocation.so.4"
  )

list(APPEND _cmake_import_check_targets QMapLibre::Location )
list(APPEND _cmake_import_check_files_for_QMapLibre::Location "${_IMPORT_PREFIX}/lib/libQMapLibreLocation.so.4.0.0" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
