#
# Boost
#
SET (Boost_DEPENDS)
ctkMacroShouldAddExternalProject(Boost_LIBRARIES add_project)
IF(${add_project})
  # Sanity checks
  IF(DEFINED BOOST_ROOT AND NOT EXISTS ${BOOST_ROOT})
    MESSAGE(FATAL_ERROR "BOOST_ROOT variable is defined but corresponds to non-existing directory")
  ENDIF()
  
  SET(proj Boost)
  SET(proj_DEPENDENCIES)
  
  SET(Boost_DEPENDS ${proj})
  
  IF(NOT DEFINED BOOST_ROOT)
    
#     MESSAGE(STATUS "Adding project:${proj}")
    ExternalProject_Add(${proj}
      URL http://www.creatis.insa-lyon.fr/software/public/creatools/crea_ThirdParty_Libraries/source/boost_1_40_0.tar.gz
      BUILD_IN_SOURCE 1  # Needed to be able to use BOOST_ROOT with FIND_PACKAGE(Boost)
      INSTALL_COMMAND ""
      CMAKE_GENERATOR ${gen}
      CMAKE_ARGS
        ${ep_common_args}
        -DBUILD_DEBUG:BOOL=OFF
        -DBUILD_STATIC:BOOL=OFF
        -DBUILD_BCP:BOOL=OFF
        -DCMAKE_CXX_FLAGS:STRING=-DBOOST_SIGNALS_NAMESPACE=boost_signals
      DEPENDS
        ${proj_DEPENDENCIES}
      )
    SET(BOOST_ROOT ${ep_source_dir}/${proj})
    
    # Since the link directories associated with Boost is used, it makes sens to 
    # update CTK_EXTERNAL_LIBRARY_DIRS with its associated library output directory
    LIST(APPEND CTK_EXTERNAL_LIBRARY_DIRS ${BOOST_ROOT}/lib)
    
  ELSE()
    ctkMacroEmptyExternalProject(${proj} "${proj_DEPENDENCIES}")
  ENDIF()
ENDIF()
