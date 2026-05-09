#----------------------------------------------------------------
# Generated CMake target import file.
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "QMapLibre::Core" for configuration ""
set_property(TARGET QMapLibre::Core APPEND PROPERTY IMPORTED_CONFIGURATIONS NOCONFIG)
set_target_properties(QMapLibre::Core PROPERTIES
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/libQMapLibre.so.3.0.0"
  IMPORTED_SONAME_NOCONFIG "libQMapLibre.so.3"
  )

list(APPEND _cmake_import_check_targets QMapLibre::Core )
list(APPEND _cmake_import_check_files_for_QMapLibre::Core "${_IMPORT_PREFIX}/lib/libQMapLibre.so.3.0.0" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
