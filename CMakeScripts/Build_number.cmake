cmake_minimum_required(VERSION 2.8.12)

# Locate Git
find_package(Git)

#if (GIT_FOUND)
#    message("git found: ${GIT_EXECUTABLE} in version     ${GIT_VERSION_STRING}")
#endif (GIT_FOUND)

SET(BUILD_FILE "/gldcore/build.h")
SET(GIT_OUTPUT git_out_${CMAKE_BUILD_TYPE})

EXECUTE_PROCESS(
        COMMAND ${GIT_EXECUTABLE} remote -v
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/CMakeScripts
        OUTPUT_FILE ${GIT_OUTPUT}_remote.tmp
        OUTPUT_STRIP_TRAILING_WHITESPACE
)
EXECUTE_PROCESS(
        COMMAND ${GIT_EXECUTABLE} status -s
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/CMakeScripts
        OUTPUT_FILE ${GIT_OUTPUT}_status.tmp
        OUTPUT_STRIP_TRAILING_WHITESPACE
)
EXECUTE_PROCESS(COMMAND ${GIT_EXECUTABLE} log --max-count=1 --format=%ad --date=raw
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/CMakeScripts
        OUTPUT_FILE ${GIT_OUTPUT}_build.tmp
        OUTPUT_STRIP_TRAILING_WHITESPACE
        )

IF (WIN32)
    SET(COMMAND_SCRIPT ".\\BuildInfo.ps1")
    MESSAGE("Using Powershell to detect build data.")
    EXECUTE_PROCESS(
            COMMAND powershell -noprofile -ExecutionPolicy Bypass -nologo -file ${COMMAND_SCRIPT} ${GIT_OUTPUT}_remote.tmp --remote
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/CMakeScripts
            OUTPUT_VARIABLE BUILD_DIR
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    #    message("BUILD_DIR: ${BUILD_DIR}")

    EXECUTE_PROCESS(
            COMMAND powershell -noprofile -ExecutionPolicy Bypass -nologo -file ${COMMAND_SCRIPT} ${GIT_OUTPUT}_status.tmp --status
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/CMakeScripts
            OUTPUT_VARIABLE MODIFY_STATUS
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    #    message("MODIFY_STATUS: ${MODIFY_STATUS}")

    EXECUTE_PROCESS(
            COMMAND powershell -noprofile -ExecutionPolicy Bypass -nologo -file ${COMMAND_SCRIPT} ${GIT_OUTPUT}_build.tmp --build
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/CMakeScripts
            OUTPUT_VARIABLE BUILD_NUM
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if (BUILD_NUM MATCHES "^[0-9]+$")
        MATH(EXPR BUILD_NUM "(${BUILD_NUM}/86400)")
    endif ()
    #    message("BUILD_NUM: ${BUILD_NUM}")
ELSE ()
    SET(COMMAND_SCRIPT "./BuildInfo.sh")
    #    MESSAGE("Using bash to detect build data.")
    EXECUTE_PROCESS(
            COMMAND bash "-c" "${COMMAND_SCRIPT} ${GIT_OUTPUT}_remote.tmp --remote"
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/CMakeScripts
            OUTPUT_VARIABLE BUILD_DIR
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )
#    message("BUILD_DIR: ${BUILD_DIR}")

    EXECUTE_PROCESS(COMMAND bash "-c" "${COMMAND_SCRIPT} ${GIT_OUTPUT}_status.tmp --status"
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/CMakeScripts
            OUTPUT_VARIABLE MODIFY_STATUS
            OUTPUT_STRIP_TRAILING_WHITESPACE
            )
#    message("MODIFY_STATUS: ${MODIFY_STATUS}")

    EXECUTE_PROCESS(COMMAND bash "-c" "${COMMAND_SCRIPT} ${GIT_OUTPUT}_build.tmp --build"
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/CMakeScripts
            OUTPUT_VARIABLE BUILD_NUM
            OUTPUT_STRIP_TRAILING_WHITESPACE
            )
    if (BUILD_NUM MATCHES "^[0-9]+$")
        MATH(EXPR BUILD_NUM "(${BUILD_NUM}/86400)")
    endif ()
#    message("BUILD_NUM: ${BUILD_NUM}")
ENDIF (WIN32)

FILE(REMOVE ${CMAKE_SOURCE_DIR}/CMakeScripts/${GIT_OUTPUT}_remote.tmp)
FILE(REMOVE ${CMAKE_SOURCE_DIR}/CMakeScripts/${GIT_OUTPUT}_status.tmp)
FILE(REMOVE ${CMAKE_SOURCE_DIR}/CMakeScripts/${GIT_OUTPUT}_build.tmp)

IF ("" STREQUAL "${MODIFY_STATUS}")
    SET(BRANCH "${GIT_COMMIT_HASH}:${GIT_BRANCH}")
ELSE ()
    SET(BRANCH "${GIT_COMMIT_HASH}:${GIT_BRANCH}:Modified")
ENDIF ()

MESSAGE("Updating ${CMAKE_CURRENT_SOURCE_DIR}${BUILD_FILE}: revision ${BUILD_NUM} (${BRANCH})")
STRING(TIMESTAMP BUILD_YEAR "%Y")
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/gldcore/build.h.in ${CMAKE_CURRENT_SOURCE_DIR}/gldcore/build.h @ONLY)
