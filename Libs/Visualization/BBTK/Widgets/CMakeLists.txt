PROJECT(CTKVisualizationBBTKWidgets)

#
# 3rd party dependencies
#
SET(Boost_USE_STATIC_LIBS OFF)
SET(Boost_USE_MULTITHREADED ON)
FIND_PACKAGE(Boost COMPONENTS signals filesystem date_time system program_options regex thread)
IF(NOT Boost_FOUND)
  MESSAGE(FATAL_ERROR "error: Boost package is required to build ${PROJECT_NAME}")
ENDIF()
INCLUDE_DIRECTORIES(${Boost_INCLUDE_DIRS})

FIND_PACKAGE(VTK)
IF(NOT VTK_FOUND)
  MESSAGE(FATAL_ERROR "error: VTK package is required to build ${PROJECT_NAME}")
ENDIF()
INCLUDE(${VTK_USE_FILE})

FIND_PACKAGE(crea)
IF(NOT crea_FOUND)
  MESSAGE(FATAL_ERROR "error: crea package is required to build ${PROJECT_NAME}")
ENDIF()
INCLUDE(${crea_USE_FILE})

FIND_PACKAGE(BBTK)
IF(NOT BBTK_FOUND)
  MESSAGE(FATAL_ERROR "error: BBTK package is required to build ${PROJECT_NAME}")
ENDIF()
INCLUDE(${BBTK_USE_FILE})

# Redefine boost signals namespace to avoid clashes with Qt
ADD_DEFINITIONS(-DBOOST_SIGNALS_NAMESPACE=boost_signals)

# Disable flags
#string(REPLACE "-Wold-style-cast" "" CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})
#string(REPLACE "-Wunused-parameter" "" CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})

#
# See CTK/CMake/ctkMacroBuildLib.cmake for details
#

SET(KIT_export_directive "CTK_VISUALIZATION_BBTK_WIDGETS_EXPORT")

# Additional directories to include
SET(KIT_include_directories
  )
  
# Source files
SET(KIT_SRCS
  ctkBBTKShell.cpp
  ctkBBTKShell.h
  )

# Headers that should run through moc
SET(KIT_MOC_SRCS
  ctkBBTKShell.h
  )

# UI files
SET(KIT_UI_FORMS
)

# Resources
SET(KIT_resources

)

#ctkMacroDisableCompilerFlags()
# Target libraries - See CMake/ctkMacroGetTargetLibraries.cmake
# The following macro will read the target libraries from the file 'target_libraries.cmake'
ctkMacroGetTargetLibraries(KIT_target_libraries)

ctkMacroBuildLib(
  NAME ${PROJECT_NAME}
  EXPORT_DIRECTIVE ${KIT_export_directive}
  INCLUDE_DIRECTORIES ${KIT_include_directories}
  SRCS ${KIT_SRCS}
  MOC_SRCS ${KIT_MOC_SRCS}
  UI_FORMS ${KIT_UI_FORMS}
  TARGET_LIBRARIES ${KIT_target_libraries}
  RESOURCES ${KIT_resources}
  LIBRARY_TYPE ${CTK_LIBRARY_MODE}
  )

# Since Boost and BBTK doesn't comply with CTK coding style, let's shutdown few warnings :(
SET_TARGET_PROPERTIES(${PROJECT_NAME}
  PROPERTIES COMPILE_FLAGS "-Wno-old-style-cast -Wno-unused-parameter")

# Plugins
#ADD_SUBDIRECTORY(Plugins)

# Testing
IF(BUILD_TESTING)
  ADD_SUBDIRECTORY(Testing)
ENDIF(BUILD_TESTING)
