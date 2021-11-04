set(KIT ${PROJECT_NAME})

set(KITTests_SRCS
  ctkDICOMAppWidgetTest1.cpp
  ctkDICOMBrowserTest.cpp
  ctkDICOMBrowserTest1.cpp
  ctkDICOMItemViewTest1.cpp
  ctkDICOMDirectoryListWidgetTest1.cpp
  ctkDICOMImageTest1.cpp
  ctkDICOMImportWidgetTest1.cpp
  ctkDICOMListenerWidgetTest1.cpp
  ctkDICOMModelTest2.cpp
  ctkDICOMObjectModelTest1.cpp
  ctkDICOMQueryResultsTabWidgetTest1.cpp
  ctkDICOMServerNodeWidgetTest1.cpp
  ctkDICOMThumbnailListWidgetTest1.cpp
  )

if(CTK_QT_VERSION VERSION_GREATER "4")
  list(APPEND KITTests_SRCS
    ctkDICOMQueryRetrieveWidgetTest1.cpp
    )
endif()

create_test_sourcelist(Tests ${KIT}CppTests.cpp
  ${KITTests_SRCS}
  )

set(Tests_MOC_CPPS
  ctkDICOMBrowserTest.cpp
  )

include_directories(
  ${CMAKE_SOURCE_DIR}/Libs/Testing
  ${CMAKE_CURRENT_BINARY_DIR}
  )

set(CTK_QT_TEST_LIBRARY )

if (CTK_QT_VERSION VERSION_GREATER "4")
  find_package(Qt5Test REQUIRED)
  set(CTK_QT_TEST_LIBRARY Qt5::Test)
  qt5_generate_mocs(${Tests_MOC_CPPS})
else()
  qt4_generate_mocs(${Tests_MOC_CPPS})
endif()

SET (TestsToRun ${Tests})
REMOVE (TestsToRun ${KIT}CppTests.cpp)

set(LIBRARY_NAME ${PROJECT_NAME})

ctk_add_executable_utf8(${KIT}CppTests ${Tests})
target_link_libraries(${KIT}CppTests ${LIBRARY_NAME} ${CTK_BASE_LIBRARIES} ${CTK_QT_TEST_LIBRARY})

#
# Add Tests
#

SIMPLE_TEST(ctkDICOMDirectoryListWidgetTest1)
SIMPLE_TEST(ctkDICOMImportWidgetTest1)
SIMPLE_TEST(ctkDICOMListenerWidgetTest1)
SIMPLE_TEST(ctkDICOMModelTest2
  ${CMAKE_CURRENT_BINARY_DIR}/dicom.db
  ${CMAKE_CURRENT_SOURCE_DIR}/../../../Core/Resources/dicom-sample.sql
  )
if(CTK_QT_VERSION VERSION_GREATER "4")
SIMPLE_TEST(ctkDICOMQueryRetrieveWidgetTest1)
endif()
SIMPLE_TEST(ctkDICOMQueryResultsTabWidgetTest1)
SIMPLE_TEST(ctkDICOMThumbnailListWidgetTest1
  ${CMAKE_CURRENT_BINARY_DIR}/dicom.db
  ${CMAKE_CURRENT_SOURCE_DIR}/../../../Core/Resources/dicom-sample.sql
  )

#
# Add Tests expecting CTKData to be set
#
if(EXISTS "${CTKData_DIR}")
  SIMPLE_TEST(ctkDICOMAppWidgetTest1 ${CTKData_DIR}/Data/DICOM/MRHEAD)
  SIMPLE_TEST(ctkDICOMBrowserTest)
  set_property(TEST ctkDICOMBrowserTest PROPERTY ENVIRONMENT "CTKData_DIR=${CTKData_DIR}")
  SIMPLE_TEST(ctkDICOMBrowserTest1 ${CTKData_DIR}/Data/DICOM/MRHEAD)
  SIMPLE_TEST(ctkDICOMItemViewTest1 ${CTKData_DIR}/Data/DICOM/MRHEAD/000055.IMA)
  SIMPLE_TEST(ctkDICOMImageTest1 ${CTKData_DIR}/Data/DICOM/MRHEAD/000055.IMA)
endif()
