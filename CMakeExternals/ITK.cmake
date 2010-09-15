#
# ITK
#
SET (ITK_DEPENDS)
ctkMacroShouldAddExternalProject(ITK_LIBRARIES add_project)
IF(${add_project})
  # Sanity checks
  IF(DEFINED ITK_DIR AND NOT EXISTS ${ITK_DIR})
    MESSAGE(FATAL_ERROR "ITK_DIR variable is defined but corresponds to non-existing directory")
  ENDIF()
  
  SET(proj ITK)
  SET(proj_DEPENDENCIES)
  
  SET(ITK_DEPENDS ${proj})
  
  IF(NOT DEFINED ITK_DIR)
    
#     MESSAGE(STATUS "Adding project:${proj}")
    ExternalProject_Add(${proj}
      URL http://voxel.dl.sourceforge.net/sourceforge/itk/InsightToolkit-3.18.0.tar.gz
      INSTALL_COMMAND ""
      CMAKE_GENERATOR ${gen}
      CMAKE_ARGS
        ${ep_common_args}
      DEPENDS
        ${proj_DEPENDENCIES}
      )
    SET(ITK_DIR ${ep_build_dir}/${proj})
    
    # Since the link directories associated with Boost is used, it makes sens to 
    # update CTK_EXTERNAL_LIBRARY_DIRS with its associated library output directory
    LIST(APPEND CTK_EXTERNAL_LIBRARY_DIRS ${ITK_DIR}/bin)
  ELSE()
    ctkMacroEmptyExternalProject(${proj} "${proj_DEPENDENCIES}")
  ENDIF()
ENDIF()
