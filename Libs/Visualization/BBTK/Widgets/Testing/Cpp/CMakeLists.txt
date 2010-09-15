SET(KIT ${PROJECT_NAME})

#
# Tests
#
SET(TEST_SOURCES
  )

#
# Tests expecting CTKData to be set
#
IF(EXISTS "${CTKData_DIR}")
  LIST(APPEND TEST_SOURCES
    ctkBBTKShellTest1.cpp
    )
ENDIF()

CREATE_TEST_SOURCELIST(Tests ${KIT}CppTests.cpp
  ${TEST_SOURCES}
  #EXTRA_INCLUDE TestingMacros.h
  )

SET (TestsToRun ${Tests})
REMOVE (TestsToRun ${KIT}CppTests.cpp)

SET(LIBRARY_NAME ${PROJECT_NAME})

ADD_EXECUTABLE(${KIT}CppTests ${Tests})
TARGET_LINK_LIBRARIES(${KIT}CppTests ${LIBRARY_NAME} ${CTK_BASE_LIBRARIES})

# Since Boost and BBTK doesn't comply with CTK coding style, let's shutdown few warnings :(
SET_TARGET_PROPERTIES(${KIT}CppTests
  PROPERTIES COMPILE_FLAGS "-Wno-old-style-cast -Wno-unused-parameter")

SET( KIT_TESTS ${CPP_TEST_PATH}/${KIT}CppTests)

MACRO( SIMPLE_TEST  TESTNAME )
  ADD_TEST( ${TESTNAME} ${KIT_TESTS} ${TESTNAME} -D "${CTKData_DIR}/Data")
  SET_PROPERTY(TEST ${TESTNAME} PROPERTY LABELS ${PROJECT_NAME})
ENDMACRO( SIMPLE_TEST  )

#
# Add Tests
#

#SIMPLE_TEST( ctkTransferFunctionBarsItemTest1 )

#
# Add Tests expecting CTKData to be set
#
IF(EXISTS "${CTKData_DIR}")
  SIMPLE_TEST( ctkBBTKShellTest1 )
ENDIF()
