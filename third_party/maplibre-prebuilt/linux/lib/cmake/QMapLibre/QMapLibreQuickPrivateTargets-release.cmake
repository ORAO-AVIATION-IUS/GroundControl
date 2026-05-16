#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "QMapLibre::QuickPrivate" for configuration "Release"
set_property(TARGET QMapLibre::QuickPrivate APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(QMapLibre::QuickPrivate PROPERTIES
  IMPORTED_LINK_DEPENDENT_LIBRARIES_RELEASE "Qt6::OpenGL;Qt6::Network"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libQMapLibreQuickPrivate.so.4.0.0"
  IMPORTED_SONAME_RELEASE "libQMapLibreQuickPrivate.so.4"
  )

list(APPEND _cmake_import_check_targets QMapLibre::QuickPrivate )
list(APPEND _cmake_import_check_files_for_QMapLibre::QuickPrivate "${_IMPORT_PREFIX}/lib/libQMapLibreQuickPrivate.so.4.0.0" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
