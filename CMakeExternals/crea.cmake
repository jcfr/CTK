#
# Crea
#
SET (crea_DEPENDS)
ctkMacroShouldAddExternalProject(crea_LIBRARIES add_project)
IF(${add_project})
  # Sanity checks
  IF(DEFINED crea_DIR AND NOT EXISTS ${crea_DIR})
    MESSAGE(FATAL_ERROR "crea_DIR variable is defined but corresponds to non-existing directory")
  ENDIF()
  
  SET(proj crea)
  SET(proj_DEPENDENCIES Boost VTK)
  
  SET(crea_DEPENDS ${proj})
  
  IF(NOT DEFINED crea_DIR)
#     MESSAGE(STATUS "Adding project:${proj}")
    
    ExternalProject_Add(${proj}
      URL http://www.creatis.insa-lyon.fr/software/public/creatools/creaTools/nightly/creaTools-src-10-09-13/crea_10-09-13.tgz
      INSTALL_COMMAND ""
      CMAKE_GENERATOR ${gen}
      CMAKE_ARGS
        ${ep_common_args}
        -DCREA_BUILD_WX:BOOL=OFF
        -DCREA_BUILD_VKT:BOOL=ON
        -DBOOST_ROOT:PATH=${BOOST_ROOT}
        -DCMAKE_CXX_FLAGS:STRING=-DBOOST_SIGNALS_NAMESPACE=boost_signals
      DEPENDS
        ${proj_DEPENDENCIES}
      )
    SET(crea_DIR ${ep_build_dir}/${proj})
    
    # Since the link directories associated with crea is used, it makes sens to 
    # update CTK_EXTERNAL_LIBRARY_DIRS with its associated library output directory
    LIST(APPEND CTK_EXTERNAL_LIBRARY_DIRS ${crea_DIR})
    
  ELSE()
    ctkMacroEmptyExternalProject(${proj} "${proj_DEPENDENCIES}")
  ENDIF()
ENDIF()
