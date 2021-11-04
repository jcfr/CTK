project(${PROJECT_NAME}Plugins)

#
# See CTK/CMake/ctkMacroBuildQtPlugin.cmake for details
#

set(PLUGIN_export_directive "CTK_DICOM_WIDGETS_PLUGINS_EXPORT")

# Source files
set(PLUGIN_SRCS
  ctkDICOMWidgetsPlugins.cpp
  ctkDICOMWidgetsPlugins.h
  ctkDICOMWidgetsAbstractPlugin.cpp
  ctkDICOMWidgetsAbstractPlugin.h

  ctkDICOMTableManagerPlugin.cpp
  ctkDICOMTableManagerPlugin.h
  ctkDICOMTableViewPlugin.cpp
  ctkDICOMTableViewPlugin.h
  )

# Headers that should run through moc
set(PLUGIN_MOC_SRCS
  ctkDICOMWidgetsPlugins.h

  ctkDICOMTableManagerPlugin.h
  ctkDICOMTableViewPlugin.h
  )

# Resources
set(PLUGIN_resources
)

if(CTK_QT_VERSION VERSION_GREATER "4")
  # Source files
  list(APPEND PLUGIN_SRCS
    ctkDICOMQueryRetrieveWidgetPlugin.cpp
    ctkDICOMQueryRetrieveWidgetPlugin.h
    )

  # Headers that should run through moc
  list(APPEND PLUGIN_MOC_SRCS
    ctkDICOMQueryRetrieveWidgetPlugin.h
    )
endif()

# Target libraries
set(PLUGIN_target_libraries
  CTKDICOMWidgets
  )

ctkMacroBuildQtDesignerPlugin(
  NAME ${PROJECT_NAME}
  EXPORT_DIRECTIVE ${PLUGIN_export_directive}
  SRCS ${PLUGIN_SRCS}
  MOC_SRCS ${PLUGIN_MOC_SRCS}
  RESOURCES ${PLUGIN_resources}
  TARGET_LIBRARIES ${PLUGIN_target_libraries}
)
