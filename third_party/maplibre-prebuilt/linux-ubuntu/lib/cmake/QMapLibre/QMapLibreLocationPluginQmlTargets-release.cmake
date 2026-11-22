#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "QMapLibre::PluginQmlLocation" for configuration "Release"
set_property(TARGET QMapLibre::PluginQmlLocation APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(QMapLibre::PluginQmlLocation PROPERTIES
  IMPORTED_COMMON_LANGUAGE_RUNTIME_RELEASE ""
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/qml/MapLibre/Location/libdeclarative_maplibre_locationplugin.so"
  IMPORTED_NO_SONAME_RELEASE "TRUE"
  )

list(APPEND _cmake_import_check_targets QMapLibre::PluginQmlLocation )
list(APPEND _cmake_import_check_files_for_QMapLibre::PluginQmlLocation "${_IMPORT_PREFIX}/qml/MapLibre/Location/libdeclarative_maplibre_locationplugin.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
