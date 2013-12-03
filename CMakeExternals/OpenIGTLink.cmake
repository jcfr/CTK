#
# OpenIGTLink
#

superbuild_include_once()

set(proj OpenIGTLink)

set(${proj}_enabling_variable OpenIGTLink_LIBRARIES)
set(${${proj}_enabling_variable}_LIBRARY_DIRS OpenIGTLink_LIBRARY_DIRS)
set(${${proj}_enabling_variable}_INCLUDE_DIRS OpenIGTLink_INCLUDE_DIRS)
set(${${proj}_enabling_variable}_FIND_PACKAGE_CMD OpenIGTLink)

set(${proj}_DEPENDENCIES "")

ctkMacroCheckExternalProjectDependency(${proj})

if(${CMAKE_PROJECT_NAME}_USE_SYSTEM_${proj})
  unset(OpenIGTLink_DIR CACHE)
  find_package(OpenIGTLink REQUIRED NO_MODULE)
endif()

# Sanity checks
if(DEFINED OpenIGTLink_DIR AND NOT EXISTS ${OpenIGTLink_DIR})
  message(FATAL_ERROR "OpenIGTLink_DIR variable is defined but corresponds to non-existing directory")
endif()

if(NOT DEFINED OpenIGTLink_DIR AND NOT ${CMAKE_PROJECT_NAME}_USE_SYSTEM_${proj})

  set(location_args )
  if(${proj}_URL)
    set(location_args URL ${${proj}_URL})
  else()
    set(location_args SVN_REPOSITORY "http://svn.na-mic.org/NAMICSandBox/trunk/OpenIGTLink")
  endif()

  set(ep_project_include_arg)
  if(CTEST_USE_LAUNCHERS)
    set(ep_project_include_arg
      "-DCMAKE_PROJECT_OpenIGTLink_INCLUDE:FILEPATH=${CMAKE_ROOT}/Modules/CTestUseLaunchers.cmake")
  endif()

  ExternalProject_Add(${proj}
    ${${proj}_EXTERNAL_PROJECT_ARGS}
    SOURCE_DIR ${CMAKE_BINARY_DIR}/${proj}
    BINARY_DIR ${proj}-build
    PREFIX ${proj}${ep_suffix}
    ${location_args}
    INSTALL_COMMAND ""
    CMAKE_GENERATOR ${gen}
    LIST_SEPARATOR ${sep}
    CMAKE_CACHE_ARGS
      ${ep_common_cache_args}
      ${ep_project_include_arg}
    DEPENDS
      ${${proj}_DEPENDENCIES}
    )
  set(OpenIGTLink_DIR ${CMAKE_BINARY_DIR}/${proj}-build)

else()
  ctkMacroEmptyExternalproject(${proj} "${${proj}_DEPENDENCIES}")
endif()

mark_as_superbuild(
  VARS OpenIGTLink_DIR:PATH
  LABELS "FIND_PACKAGE"
  )
