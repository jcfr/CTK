###########################################################################
#
#  Library:   CTK
#
#  Copyright (c) Kitware Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0.txt
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################

include(CMakeParseArguments)
include(ExternalProject)
include(ctkListToString)

if(NOT DEFINED EP_LIST_SEPARATOR)
  set(EP_LIST_SEPARATOR "^^")
endif()

if(NOT EXISTS "${EXTERNAL_PROJECT_DIR}")
  set(EXTERNAL_PROJECT_DIR ${${CMAKE_PROJECT_NAME}_SOURCE_DIR}/SuperBuild)
endif()

if(NOT DEFINED EXTERNAL_PROJECT_FILE_PREFIX)
  set(EXTERNAL_PROJECT_FILE_PREFIX "External_")
endif()

#
# superbuild_include_once()
#
# superbuild_include_once() is a macro intented to be used as include guard.
#
# It ensures that the CMake code placed after the include guard in a CMake file included
# using either 'include(/path/to/file.cmake)' or 'include(cmake_module)' will be executed
# once.
#
# It internally set the global property '<CMAKE_CURRENT_LIST_FILENAME>_FILE_INCLUDED' to check if
# a file has already been included.
#
macro(superbuild_include_once)
  # Make sure this file is included only once
  get_filename_component(CMAKE_CURRENT_LIST_FILENAME ${CMAKE_CURRENT_LIST_FILE} NAME_WE)
  set(_property_name ${CMAKE_CURRENT_LIST_FILENAME}_FILE_INCLUDED)
  get_property(${_property_name} GLOBAL PROPERTY ${_property_name})
  if(${_property_name})
    return()
  endif()
  set_property(GLOBAL PROPERTY ${_property_name} 1)
endmacro()

#!
#! mark_as_superbuild(<varname1>[:<vartype1>] [<varname2>[:<vartype2>] [...]])
#!
#! mark_as_superbuild(
#!     VARS <varname1>[:<vartype1>] [<varname2>[:<vartype2>] [...]]
#!     [PROJECT <projectname>]
#!     [LABELS <label1> [<label2> [...]]]
#!   )
#!
#! PROJECT corresponds to a <projectname> that is already or will be added using 'ExternalProject_Add' function.
#!         If not specified and called within a project file, it defaults to the value of 'SUPERBUILD_TOPLEVEL_PROJECT'
#!         Otherwise, it defaults to 'CMAKE_PROJECT_NAME'.
#!
#! VARS is an expected list of variables specified as <varname>:<vartype> to pass to <projectname>
#!
#!
#! LABELS is an optional list of label to associate with the variable names specified using 'VARS' and passed to
#!        the <projectname> as CMake args of the form:
#!          -D<projectname>_EP_CMAKE_ARG_LABEL_<label1>=<varname1>^^<varname2>[...]
#!          -D<projectname>_EP_CMAKE_ARG_LABEL_<label2>=<varname1>^^<varname2>[...]
#!
function(mark_as_superbuild)
  set(options)
  set(oneValueArgs PROJECT)
  set(multiValueArgs VARS LABELS)
  cmake_parse_arguments(_sb "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  set(_vars ${_sb_UNPARSED_ARGUMENTS})

  set(_named_parameters_expected 0)
  if(_sb_PROJECT OR _sb_LABELS OR _sb_VARS)
    set(_named_parameters_expected 1)
    set(_vars ${_sb_VARS})
  endif()

  if(_named_parameters_expected AND _sb_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Arguments '${_sb_UNPARSED_ARGUMENTS}' should be associated with VARS parameter !")
  endif()

  foreach(var ${_vars})
    set(_type_specified 0)
    if(${var} MATCHES ":")
      set(_type_specified 1)
    endif()
    # XXX Display warning with variable type is also specified for cache variable.
    set(_var ${var})
    if(NOT _type_specified)
      get_property(_type_set_in_cache CACHE ${_var} PROPERTY TYPE SET)
      set(_var_name ${_var})
      set(_var_type "STRING")
      if(_type_set_in_cache)
        get_property(_var_type CACHE ${_var_name} PROPERTY TYPE)
      endif()
      set(_var ${_var_name}:${_var_type})
    endif()
    list(APPEND _vars_with_type ${_var})
  endforeach()
  _sb_append_to_cmake_args(VARS ${_vars_with_type} PROJECT ${_sb_PROJECT} LABELS ${_sb_LABELS})
endfunction()

#!
#! _sb_extract_varname_and_vartype(<cmake_varname_and_type> <varname_var> [<vartype_var>])
#!
#! <cmake_varname_and_type> corresponds to variable name and variable type passed as "<varname>:<vartype>"
#!
#! <varname_var> will be set to "<varname>"
#!
#! <vartype_var> is an optional variable name that will be set to "<vartype>"
function(_sb_extract_varname_and_vartype cmake_varname_and_type varname_var)
  set(_vartype_var ${ARGV2})
  string(REPLACE ":" ";" varname_and_vartype ${cmake_varname_and_type})
  list(GET varname_and_vartype 0 _varname)
  list(GET varname_and_vartype 1 _vartype)
  set(${varname_var} ${_varname} PARENT_SCOPE)
  if(_vartype_var MATCHES ".+")
    set(${_vartype_var} ${_vartype} PARENT_SCOPE)
  endif()
endfunction()

#!
#! superbuild_cmakevar_to_cmakearg(<cmake_varname_and_type> <cmake_arg_var> [<varname_var> [<vartype_var>]])
#!
#! <cmake_varname_and_type> corresponds to variable name and variable type passed as "<varname>:<vartype>"
#!
#! <cmake_arg_var> is a variable name that will be set to "-D<varname>:<vartype>=${<varname>}"
#!
#! <varname_var> is an optional variable name that will be set to "<varname>"
#!
#! <vartype_var> is an optional variable name that will be set to "<vartype>"
function(superbuild_cmakevar_to_cmakearg cmake_varname_and_type cmake_arg_var)
  set(_varname_var ${ARGV2})
  set(_vartype_var ${ARGV3})

  _sb_extract_varname_and_vartype(${cmake_varname_and_type} _varname _vartype)

  set(_var_value "${${_varname}}")
  get_property(_value_set_in_cache CACHE ${_varname} PROPERTY VALUE SET)
  if(_value_set_in_cache)
    get_property(_var_value CACHE ${_varname} PROPERTY VALUE)
  endif()

  # Separate list item with <EP_LIST_SEPARATOR>
  set(ep_arg_as_string "")
  ctk_list_to_string(${EP_LIST_SEPARATOR} "${_var_value}" ep_arg_as_string)

  set(${cmake_arg_var} -D${_varname}:${_vartype}=${ep_arg_as_string} PARENT_SCOPE)

  if(_varname_var MATCHES ".+")
    set(${_varname_var} ${_varname} PARENT_SCOPE)
  endif()
  if(_vartype_var MATCHES ".+")
    set(${_vartype_var} ${_vartype} PARENT_SCOPE)
  endif()
endfunction()

#!
#! _sb_append_to_cmake_args(
#!     VARS <varname1>:<vartype1> [<varname2>:<vartype2> [...]]
#!     [PROJECT <projectname>]
#!     [LABELS <label1> [<label2> [...]]]
#!   )
#!
#! PROJECT corresponds to a <projectname> that is already or will be added using 'ExternalProject_Add' function.
#!         If not specified and called within a project file, it defaults to the value of 'SUPERBUILD_TOPLEVEL_PROJECT'
#!         Otherwise, it defaults to 'CMAKE_PROJECT_NAME'.
#!
#! VARS is an expected list of variables specified as <varname>:<vartype> to pass to <projectname>
#!
#!
#! LABELS is an optional list of label to associate with the variable names specified using 'VARS' and passed to
#!        the <projectname> as CMake args of the form:
#!          -D<projectname>_EP_CMAKE_ARG_LABEL_<label1>=<varname1>^^<varname2>[...]
#!          -D<projectname>_EP_CMAKE_ARG_LABEL_<label2>=<varname1>^^<varname2>[...]
#!
function(_sb_append_to_cmake_args)
  set(options)
  set(oneValueArgs PROJECT)
  set(multiValueArgs VARS LABELS)
  cmake_parse_arguments(_sb "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT _sb_PROJECT)
    if(SUPERBUILD_TOPLEVEL_PROJECT)
      set(_sb_PROJECT ${SUPERBUILD_TOPLEVEL_PROJECT})
    else()
      set(_sb_PROJECT ${CMAKE_PROJECT_NAME})
    endif()
  endif()

  set(_ep_varnames "")
  set(_ep_property "CMAKE_ARGS")
  foreach(varname_and_vartype ${_sb_VARS})
    if(NOT TARGET ${_sb_PROJECT})
      set_property(GLOBAL APPEND PROPERTY ${_sb_PROJECT}_EP_${_ep_property} ${varname_and_vartype})
      _sb_extract_varname_and_vartype(${varname_and_vartype} _varname)
      set_property(GLOBAL APPEND PROPERTY ${_sb_PROJECT}_EP_PROPERTIES ${_ep_property})
    else()
      superbuild_cmakevar_to_cmakearg(${var} cmake_arg _varname)
      superbuild_append_to_external_project_property(
        PROJECT ${_sb_PROJECT} PROPERTY ${_ep_property}
        VALUES ${cmake_arg})
    endif()
    list(APPEND _ep_varnames ${_varname})
  endforeach()

  if(_sb_LABELS)
    set_property(GLOBAL APPEND PROPERTY ${_sb_PROJECT}_EP_CMAKE_ARG_LABELS ${_sb_LABELS})
    foreach(label ${_sb_LABELS})
      set_property(GLOBAL APPEND PROPERTY ${_sb_PROJECT}_EP_CMAKE_ARG_LABEL_${label} ${_ep_varnames})
    endforeach()
  endif()
endfunction()

#!
#! superbuild_append_to_external_project_property(
#!     PROJECT <projectname>
#!     PROPERTY <arg_name>
#!     VALUES <value1>[;<value2>[...]]
#!  )
#!
#! PROJECT corresponds to a <projectname> that is already or will be added using 'ExternalProject_Add' function.
#!
#! PROPERTY is the name of an argument supported by 'ExternalProject_Add' function.
#!
#! VALUES is a list of value to append to the external project argument identified by <arg_name>.
#!
function(superbuild_append_to_external_project_property)
  set(options)
  set(oneValueArgs PROJECT PROPERTY)
  set(multiValueArgs VALUES)
  cmake_parse_arguments(_sb "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  # Validate property name
  if(NOT ${_sb_PROPERTY} MATCHES ${_ep_keywords_ExternalProject_Add})
    message(FATAL_ERROR "'${_sb_PROPERTY}' is not a known ExternalProject property !")
  endif()

  if(TARGET ${_sb_PROJECT})
    set(ns "_EP_")
    set(key ${_sb_PROPERTY})
    set_property(TARGET ${_sb_PROJECT} APPEND PROPERTY ${ns}${key} ${_sb_VALUES})
  else()
    set_property(GLOBAL APPEND PROPERTY ${_sb_PROJECT}_EP_PROPERTIES ${_sb_PROPERTY})
    set_property(GLOBAL APPEND PROPERTY ${_sb_PROJECT}_EP_PROPERTY_${_sb_PROPERTY} ${_sb_VALUES})
  endif()
endfunction()

function(_sb_get_external_project_arguments proj varname)

  set(_ep_arguments "")

  # Set list of CMake args associated with each label
  get_property(_labels GLOBAL PROPERTY ${proj}_EP_CMAKE_ARG_LABELS)
  list(REMOVE_DUPLICATES _labels)
  foreach(label ${_labels})
    get_property(${proj}_EP_CMAKE_ARG_LABEL_${label} GLOBAL PROPERTY ${proj}_EP_CMAKE_ARG_LABEL_${label})
    list(REMOVE_DUPLICATES ${proj}_EP_CMAKE_ARG_LABEL_${label})
    _sb_append_to_cmake_args(VARS ${proj}_EP_CMAKE_ARG_LABEL_${label}:STRING)
  endforeach()

  get_property(_args GLOBAL PROPERTY ${proj}_EP_CMAKE_ARGS)
  foreach(var ${_args})
    superbuild_cmakevar_to_cmakearg(${var} cmake_arg)
    set_property(GLOBAL APPEND PROPERTY ${proj}_EP_PROPERTY_CMAKE_ARGS ${cmake_arg})
  endforeach()

  get_property(_properties GLOBAL PROPERTY ${proj}_EP_PROPERTIES)
  list(REMOVE_DUPLICATES _properties)
  foreach(property ${_properties})
    get_property(${proj}_EP_PROPERTY_${property} GLOBAL PROPERTY ${proj}_EP_PROPERTY_${property})
    list(APPEND _ep_arguments ${property} ${${proj}_EP_PROPERTY_${property}})
  endforeach()

  list(APPEND _ep_arguments LIST_SEPARATOR ${EP_LIST_SEPARATOR})

  set(${varname} ${_ep_arguments} PARENT_SCOPE)
endfunction()

function(_sb_update_indent proj)
  superbuild_stack_size(SUPERBUILD_PROJECT_STACK _stack_size)
  set(_indent "")
  if(_stack_size GREATER 0)
    foreach(not_used RANGE 1 ${_stack_size})
      set(_indent "  ${_indent}")
    endforeach()
  endif()
  set_property(GLOBAL PROPERTY SUPERBUILD_${proj}_INDENT ${_indent})
endfunction()

function(superbuild_message proj msg)
  if(NOT __epd_first_pass)
    get_property(_indent GLOBAL PROPERTY SUPERBUILD_${proj}_INDENT)
    message(STATUS "SuperBuild - ${_indent}${msg}")
  endif()
endfunction()

#!
#! superbuild_stack_content(<stack_name> <output_var>)
#!
#! <stack_name> corresponds to the name of stack.
#!
#! <output_var> is the name of CMake variable that will be set with the content
#! of the stack identified by <stack_name>.
function(superbuild_stack_content stack_name output_var)
  get_property(_stack GLOBAL PROPERTY ${stack_name})
  set(${output_var} ${_stack} PARENT_SCOPE)
endfunction()

#!
#! superbuild_stack_size(<stack_name> <output_var>)
#!
#! <stack_name> corresponds to the name of stack.
#!
#! <output_var> is the name of CMake variable that will be set with the size
#! of the stack identified by <stack_name>.
function(superbuild_stack_size stack_name output_var)
  get_property(_stack GLOBAL PROPERTY ${stack_name})
  list(LENGTH _stack _stack_size)
  set(${output_var} ${_stack_size} PARENT_SCOPE)
endfunction()

#!
#! superbuild_stack_push(<stack_name> <value>)
#!
#! <stack_name> corresponds to the name of stack.
#!
#! <value> is appended to the stack identified by <stack_name>.
function(superbuild_stack_push stack_name value)
  set_property(GLOBAL APPEND PROPERTY ${stack_name} ${value})
endfunction()

#!
#! superbuild_stack_pop(<stack_name> <item_var>)
#!
#! <stack_name> corresponds to the name of stack.
#!
#! <item_var> names a CMake variable that will be set with the item
#! removed from the stack identified by <stack_name>.
function(superbuild_stack_pop stack_name item_var)
  get_property(_stack GLOBAL PROPERTY ${stack_name})
  list(LENGTH _stack _stack_size)
  if(_stack_size GREATER 0)
    math(EXPR _index_to_remove "${_stack_size} - 1")
    list(GET _stack ${_index_to_remove} _item)
    list(REMOVE_AT _stack ${_index_to_remove})
    set_property(GLOBAL PROPERTY ${stack_name} ${_stack})
    set(${item_var} ${_item} PARENT_SCOPE)
  endif()
endfunction()

#
# superbuild_include_dependencies(<project>)
#
# superbuild_include_dependencies(PROJECT_VAR <project_var>)
#
macro(superbuild_include_dependencies)
  set(options)
  set(oneValueArgs PROJECT_VAR)
  set(multiValueArgs)
  cmake_parse_arguments(_sb "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  # XXX Implement invalid parameter checking

  if(NOT "x" STREQUAL "x${_sb_PROJECT_VAR}")
    set(proj ${${_sb_PROJECT_VAR}})
  else()
    set(proj ${_sb_UNPARSED_ARGUMENTS})
  endif()

  # Sanity checks
  if(NOT DEFINED ${proj}_DEPENDENCIES)
    message(FATAL_ERROR "${proj}_DEPENDENCIES variable is NOT defined !")
  endif()

  superbuild_stack_size(SUPERBUILD_PROJECT_STACK _stack_size)
  if(_stack_size EQUAL 0)
    set(SUPERBUILD_TOPLEVEL_PROJECT ${proj})
  endif()

  _sb_update_indent(${proj})

  # Keep track of the projects
  list(APPEND __epd_${SUPERBUILD_TOPLEVEL_PROJECT}_projects ${proj})

  # Is this the first run ? (used to set the <SUPERBUILD_TOPLEVEL_PROJECT>_USE_SYSTEM_* variables)
  if(${proj} STREQUAL ${SUPERBUILD_TOPLEVEL_PROJECT} AND NOT DEFINED __epd_first_pass)
    message(STATUS "SuperBuild - First pass")
    set(__epd_first_pass TRUE)
  endif()

  # Display dependency of project being processed
  if("${${proj}_DEPENDENCIES}" STREQUAL "")
    set(_msg "${proj}[OK]")
    if(${SUPERBUILD_TOPLEVEL_PROJECT}_USE_SYSTEM_${proj})
      set(_msg "${_msg} (SYSTEM)")
    endif()
    superbuild_message(${proj} ${_msg})
  else()
    set(dependency_str " ")
    foreach(dep ${${proj}_DEPENDENCIES})
      get_property(_is_included GLOBAL PROPERTY ${EXTERNAL_PROJECT_FILE_PREFIX}${dep}_FILE_INCLUDED)
      if(_is_included)
        set(dependency_str "${dependency_str}${dep}[INCLUDED], ")
      else()
        set(dependency_str "${dependency_str}${dep}, ")
      endif()
    endforeach()
    superbuild_message(${proj} "${proj} => Requires${dependency_str}")
  endif()

  foreach(dep ${${proj}_DEPENDENCIES})
    if(${${SUPERBUILD_TOPLEVEL_PROJECT}_USE_SYSTEM_${proj}})
      set(${SUPERBUILD_TOPLEVEL_PROJECT}_USE_SYSTEM_${dep} ${${SUPERBUILD_TOPLEVEL_PROJECT}_USE_SYSTEM_${proj}})
    endif()
    #if(__epd_first_pass)
    #  message("${SUPERBUILD_TOPLEVEL_PROJECT}_USE_SYSTEM_${dep} set to [${SUPERBUILD_TOPLEVEL_PROJECT}_USE_SYSTEM_${proj}:${${SUPERBUILD_TOPLEVEL_PROJECT}_USE_SYSTEM_${proj}}]")
    #endif()
  endforeach()

  superbuild_stack_push(SUPERBUILD_PROJECT_STACK ${proj})

  # Include dependencies
  foreach(dep ${${proj}_DEPENDENCIES})
    get_property(_is_included GLOBAL PROPERTY External_${dep}_FILE_INCLUDED)
    if(NOT _is_included)
      # XXX - Refactor - Add a single variable named 'EXTERNAL_PROJECT_DIRS'
      if(EXISTS "${EXTERNAL_PROJECT_DIR}/${EXTERNAL_PROJECT_FILE_PREFIX}${dep}.cmake")
        include(${EXTERNAL_PROJECT_DIR}/${EXTERNAL_PROJECT_FILE_PREFIX}${dep}.cmake)
      elseif(EXISTS "${${dep}_FILEPATH}")
        include(${${dep}_FILEPATH})
      elseif(EXISTS "${EXTERNAL_PROJECT_ADDITIONAL_DIR}/${EXTERNAL_PROJECT_FILE_PREFIX}${dep}.cmake")
        include(${EXTERNAL_PROJECT_ADDITIONAL_DIR}/${EXTERNAL_PEXCLUDEDROJECT_FILE_PREFIX}${dep}.cmake)
      else()
        message(FATAL_ERROR "Can't find ${EXTERNAL_PROJECT_FILE_PREFIX}${dep}.cmake")
      endif()
    endif()
  endforeach()

  superbuild_stack_pop(SUPERBUILD_PROJECT_STACK proj)

  # If project being process has dependencies, indicates it has also been added.
  if(NOT "${${proj}_DEPENDENCIES}" STREQUAL "")
    set(_msg "${proj}[OK]")
    if(${SUPERBUILD_TOPLEVEL_PROJECT}_USE_SYSTEM_${proj})
      set(_msg "${_ok_message} (SYSTEM)")
    endif()
    superbuild_message(${proj} ${_msg})
  endif()

  if(${proj} STREQUAL ${SUPERBUILD_TOPLEVEL_PROJECT} AND __epd_first_pass)
    message(STATUS "SuperBuild - First pass - done")
    if(${SUPERBUILD_TOPLEVEL_PROJECT}_SUPERBUILD)
      set(__epd_first_pass FALSE)
    endif()

    unset(${SUPERBUILD_TOPLEVEL_PROJECT}_DEPENDENCIES) # XXX - Refactor

    foreach(possible_proj ${__epd_${SUPERBUILD_TOPLEVEL_PROJECT}_projects})

      set_property(GLOBAL PROPERTY ${EXTERNAL_PROJECT_FILE_PREFIX}${possible_proj}_FILE_INCLUDED 0)

      if(NOT ${possible_proj} STREQUAL ${SUPERBUILD_TOPLEVEL_PROJECT})
        set(_include_project 1)
        if(COMMAND superbuild_is_external_project_includable)
          superbuild_is_external_project_includable("${possible_proj}" _include_project)
        endif()
        if(_include_project)
          list(APPEND ${SUPERBUILD_TOPLEVEL_PROJECT}_DEPENDENCIES ${possible_proj})
        else()
          superbuild_message(STATUS "${possible_proj}[OPTIONAL]")
        endif()
      endif()
    endforeach()

    list(REMOVE_DUPLICATES ${SUPERBUILD_TOPLEVEL_PROJECT}_DEPENDENCIES)

    if(${SUPERBUILD_TOPLEVEL_PROJECT}_SUPERBUILD)

      superbuild_include_dependencies(${SUPERBUILD_TOPLEVEL_PROJECT})

      set(proj ${SUPERBUILD_TOPLEVEL_PROJECT})
      unset(${proj}_EXTERNAL_PROJECT_ARGS)
      _sb_get_external_project_arguments(${proj} ${proj}_EXTERNAL_PROJECT_ARGS)
      #message("${proj}_EXTERNAL_PROJECT_ARGS:${${proj}_EXTERNAL_PROJECT_ARGS}")
    endif()

  endif()

  if(_sb_PROJECT_VAR)
    set(${_sb_PROJECT_VAR} ${proj})
  endif()

  if(__epd_first_pass)
    return()
  endif()
endmacro()

#!
#! Convenient macro allowing to define a "empty" project in case an external one is provided
#! using for example <proj>_DIR.
#! Doing so allows to keep the external project dependency system happy.
#!
#! \ingroup CMakeUtilities
macro(superbuild_add_empty_external_project proj dependencies)

  ExternalProject_Add(${proj}
    SOURCE_DIR ${CMAKE_BINARY_DIR}/${proj}
    BINARY_DIR ${proj}-build
    DOWNLOAD_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    DEPENDS
      ${dependencies}
    )
endmacro()
