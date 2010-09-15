#
# BBTK
#
SET (BBTK_DEPENDS)
ctkMacroShouldAddExternalProject(BBTK_LIBRARIES add_project)
IF(${add_project})
  # Sanity checks
  IF(DEFINED BBTK_DIR AND NOT EXISTS ${BBTK_DIR})
    MESSAGE(FATAL_ERROR "BBTK_DIR variable is defined but corresponds to non-existing directory")
  ENDIF()
  
  SET(proj BBTK)
  SET(proj_DEPENDENCIES crea)
  
  SET(BBTK_DEPENDS ${proj})
  
  IF(NOT DEFINED BBTK_DIR)
#     MESSAGE(STATUS "Adding project:${proj}")
    ExternalProject_Add(${proj}
      URL http://www.creatis.insa-lyon.fr/software/public/creatools/creaTools/nightly/creaTools-src-10-09-13/bbtk_10-09-13.tgz
      INSTALL_COMMAND ""
      CMAKE_GENERATOR ${gen}
      CMAKE_ARGS
        ${ep_common_args}
        -DBOOST_ROOT:PATH=${BOOST_ROOT}
        -DCMAKE_CXX_FLAGS:STRING=-DBOOST_SIGNALS_NAMESPACE=boost_signals
        -Dcrea_DIR:PATH=${crea_DIR}
        -DQT_QMAKE_EXECUTABLE:FILEPATH=${QT_QMAKE_EXECUTABLE}
        -DVTK_DIR:PATH=${VTK_DIR}
        -DBBTK_COMPILE_DEBUG_MESSAGES:BOOL=ON
        -DBBTK_COMPILE_ERROR_MESSAGES:BOOL=ON
        -DBBTK_COMPILE_MESSAGES:BOOL=ON
        -DBBTK_COMPILE_WARNING_MESSAGES:BOOL=ON
        -DBBTK_USE_QT:BOOL=ON
        -DBBTK_USE_WXWIDGETS:BOOL=OFF 
        -DBUILD_APPLICATIONS:BOOL=ON
        -DBUILD_BBS_APPLI_BINARIES:BOOL=OFF
        -DBUILD_BBTK_DOC:BOOL=OFF
        -DBUILD_BBTK_PACKAGE_appli:BOOL=OFF
        -DBUILD_BBTK_PACKAGE_demo:BOOL=OFF
        -DBUILD_BBTK_PACKAGE_gdcmvtk:BOOL=OFF
        -DBUILD_BBTK_PACKAGE_itk:BOOL=OFF
        -DBUILD_BBTK_PACKAGE_itkvtk:BOOL=OFF
        -DBUILD_BBTK_PACKAGE_std:BOOL=ON
        -DBUILD_BBTK_PACKAGE_toolsbbtk:BOOL=OFF
        -DBUILD_BBTK_PACKAGE_vtk:BOOL=ON
        -DBUILD_BBTK_PACKAGE_wx:BOOL=OFF
        -DBUILD_BBTK_PACKAGE_wxvtk:BOOL=OFF
      DEPENDS
        ${proj_DEPENDENCIES}
      )
    SET(BBTK_DIR ${ep_build_dir}/${proj})
    
    # Since the link directories associated with BBTK is used, it makes sens to 
    # update CTK_EXTERNAL_LIBRARY_DIRS with its associated library output directory
    LIST(APPEND CTK_EXTERNAL_LIBRARY_DIRS ${BBTK_DIR}/bin)
    
  ELSE()
    ctkMacroEmptyExternalProject(${proj} "${proj_DEPENDENCIES}")
  ENDIF()
ENDIF()
