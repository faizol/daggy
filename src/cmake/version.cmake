include (CMakeParseArguments)

macro(SET_GIT_VERSION)
    set(args PATTERN POSTFIX EXPORT)
    cmake_parse_arguments(GIT_VERSION
                          ""
                          "${args}"
                          ""
                          ${ARGN}
    )
    if(NOT VERSION)
        if (NOT GIT_VERSION_PATTERN)
            set(GIT_VERSION_PATTERN [0-9]*.[0-9]*.[0-9]*)
        endif()
        find_package(Git REQUIRED)
        execute_process(COMMAND
                "${GIT_EXECUTABLE}"
                describe
                --match ${GIT_VERSION_PATTERN}
                --abbrev=0
                --tags
                WORKING_DIRECTORY
                "${CMAKE_CURRENT_SOURCE_DIR}"
                OUTPUT_VARIABLE
                VERSION
                OUTPUT_STRIP_TRAILING_WHITESPACE)
        execute_process(COMMAND
                "${GIT_EXECUTABLE}"
                rev-list
                ${VERSION}..
                --count
                WORKING_DIRECTORY
                "${CMAKE_CURRENT_SOURCE_DIR}"
                OUTPUT_VARIABLE
                BUILD_NUMBER
                OUTPUT_STRIP_TRAILING_WHITESPACE)
        execute_process(COMMAND
                "${GIT_EXECUTABLE}"
                branch
                --show-current
                WORKING_DIRECTORY
                "${CMAKE_CURRENT_SOURCE_DIR}"
                OUTPUT_VARIABLE
                GIT_VERSION_POSTFIX
                OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        execute_process(COMMAND
                "${GIT_EXECUTABLE}"
                rev-parse
                HEAD
                WORKING_DIRECTORY
                "${CMAKE_CURRENT_SOURCE_DIR}"
                OUTPUT_VARIABLE
                GIT_VERSION_COMMIT
                OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        set(VERSION ${VERSION}.${BUILD_NUMBER})
        if (GIT_VERSION_POSTFIX STREQUAL "master")
            unset(GIT_VERSION_POSTFIX)
        endif()
    endif()

    if (GIT_VERSION_POSTFIX)
        set(VERSION ${VERSION}-${GIT_VERSION_POSTFIX})
    endif()

    set(PROJECT_VERSION_COMMIT ${GIT_VERSION_COMMIT})

    set(PROJECT_VERSION_FULL ${VERSION})
    string(REPLACE "-" ";" VERSION_LIST ${PROJECT_VERSION_FULL})
    list(LENGTH VERSION_LIST LIST_SIZE)
    list(GET VERSION_LIST 0 PROJECT_VERSION)
    if(LIST_SIZE GREATER 1)
        list(GET VERSION_LIST 1 PROJECT_VERSION_POSTFIX)
    endif()

    string(REPLACE "." ";" VERSION_LIST ${PROJECT_VERSION})
    list(LENGTH VERSION_LIST VERSION_NUMBERS_COUNT)
    if(${VERSION_NUMBERS_COUNT} LESS 3)
        message(FATAL_ERROR "Incorrect version format")
    endif()
    list(GET VERSION_LIST 0 PROJECT_VERSION_MAJOR)
    list(GET VERSION_LIST 1 PROJECT_VERSION_MINOR)
    list(GET VERSION_LIST 2 PROJECT_VERSION_PATCH)
    if (${VERSION_NUMBERS_COUNT} GREATER 3)
        list(GET VERSION_LIST 3 PROJECT_VERSION_TWEAK)
    else()
        set(PROJECT_VERSION_TWEAK 0)
    endif()

    string(TOUPPER ${PROJECT_NAME} PROJECT_NAME_UPPER)

    add_definitions(-D${PROJECT_NAME_UPPER}_VERSION_FULL="${PROJECT_VERSION_FULL}")
    add_definitions(-D${PROJECT_NAME_UPPER}_VERSION="${PROJECT_VERSION}")
    add_definitions(-D${PROJECT_NAME_UPPER}_VERSION_MAJOR=${PROJECT_VERSION_MAJOR})
    add_definitions(-D${PROJECT_NAME_UPPER}_VERSION_MINOR=${PROJECT_VERSION_MINOR})
    add_definitions(-D${PROJECT_NAME_UPPER}_VERSION_PATCH=${PROJECT_VERSION_PATCH})
    add_definitions(-D${PROJECT_NAME_UPPER}_VERSION_BUILD=${PROJECT_VERSION_TWEAK})
    add_definitions(-D${PROJECT_NAME_UPPER}_VERSION_POSTFIX="${PROJECT_VERSION_POSTFIX}")
    add_definitions(-D${PROJECT_NAME_UPPER}_VERSION_COMMIT="${PROJECT_VERSION_COMMIT}")

    add_definitions(-D${PROJECT_NAME_UPPER}_NAME="${PROJECT_NAME}")
    add_definitions(-D${PROJECT_NAME_UPPER}_VENDOR="${PROJECT_VENDOR}")
    add_definitions(-D${PROJECT_NAME_UPPER}_HOMEPAGE_URL="${PROJECT_HOMEPAGE_URL}")
endmacro()
