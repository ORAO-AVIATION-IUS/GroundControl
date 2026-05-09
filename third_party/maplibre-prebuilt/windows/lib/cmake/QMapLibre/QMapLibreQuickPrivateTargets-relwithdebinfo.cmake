#----------------------------------------------------------------
# Generated CMake target import file for configuration "RelWithDebInfo".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "QMapLibre::QuickPrivate" for configuration "RelWithDebInfo"
set_property(TARGET QMapLibre::QuickPrivate APPEND PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO)
set_target_properties(QMapLibre::QuickPrivate PROPERTIES
  IMPORTED_IMPLIB_RELWITHDEBINFO "${_IMPORT_PREFIX}/lib/QMapLibreQuickPrivate.lib"
  IMPORTED_LINK_DEPENDENT_LIBRARIES_RELWITHDEBINFO "Qt6::OpenGL;Qt6::Network"
  IMPORTED_LOCATION_RELWITHDEBINFO "${_IMPORT_PREFIX}/bin/QMapLibreQuickPrivate.dll"
  )

list(APPEND _cmake_import_check_targets QMapLibre::QuickPrivate )
list(APPEND _cmake_import_check_files_for_QMapLibre::QuickPrivate "${_IMPORT_PREFIX}/lib/QMapLibreQuickPrivate.lib" "${_IMPORT_PREFIX}/bin/QMapLibreQuickPrivate.dll" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
