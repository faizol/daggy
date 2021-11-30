set(CPACK_PACKAGE_VENDOR ${PROJECT_VENDOR})
set(CPACK_PACKAGE_CONTACT milovidovmikhail@gmail.com)
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION_FULL})
set(CPACK_PACKAGE_VERSION_MAJOR "${PROJECT_VERSION_MAJOR}")
set(CPACK_PACKAGE_VERSION_MINOR "${PROJECT_VERSION_MINOR}")
set(CPACK_PACKAGE_VERSION_PATCH "${PROJECT_VERSION_PATCH}")


if(WIN32)
    set(CPACK_GENERATOR ZIP IFW)
    set(CPACK_IFW_ROOT "C:/QtIFW")
    set(CPACK_PACKAGE_INSTALL_DIRECTORY ${CPACK_PACKAGE_NAME})

    set(CPACK_PACKAGE_ICON "${CMAKE_CURRENT_SOURCE_DIR}/icons/daggy.ico")
    set(CPACK_IFW_PACKAGE_ICON "${CMAKE_CURRENT_SOURCE_DIR}/icons/daggy.ico")
elseif(APPLE)
    set(CPACK_GENERATOR ZIP IFW)
    set(CPACK_IFW_ROOT "~/QtIFW")

    set(CPACK_PACKAGE_INSTALL_DIRECTORY ${CPACK_PACKAGE_NAME})
    set(CPACK_PACKAGE_ICON "${CMAKE_CURRENT_SOURCE_DIR}/icons/daggy.icns")
    set(CPACK_IFW_PACKAGE_ICON "${CMAKE_CURRENT_SOURCE_DIR}/icons/daggy.icns")
else()
    set(CPACK_GENERATOR DEB RPM ZIP)

    set(CPACK_PACKAGE_ICON "${CMAKE_CURRENT_SOURCE_DIR}/icons/daggy.png")
endif()

set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/../LICENSE")
set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/desc/readme.txt")
set(CPACK_RESOURCE_FILE_WELCOME "${CMAKE_CURRENT_SOURCE_DIR}/desc/welcome.txt")
set(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/desc/package_description.txt")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Data Aggregation Utility")

set(CPACK_PACKAGE_HOMEPAGE_URL "https://daggy.dev")


# TGZ specific
set(CPACK_ARCHIVE_COMPONENT_INSTALL OFF)
# DEB specific
set(CPACK_DEB_COMPONENT_INSTALL OFF)
set(CPACK_DEBIAN_PACKAGE_MAINTAINER ${CPACK_PACKAGE_VENDOR})

# RPM specific
set(CPACK_RPM_COMPONENT_INSTALL OFF)
set(CPACK_RPM_PACKAGE_AUTOREQ NO)
set(CPACK_RPM_PACKAGE_LICENSE MIT)

set(CPACK_SYSTEM_NAME ${CMAKE_SYSTEM_NAME})
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/../LICENSE")
set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/../README.md")

set(CPACK_IFW_PRODUCT_URL "https://daggy.dev")
set(CPACK_IFW_PACKAGE_WINDOW_ICON "${CMAKE_CURRENT_SOURCE_DIR}/icons/daggy.png")
set(CPACK_IFW_PACKAGE_LOGO "${CMAKE_CURRENT_SOURCE_DIR}/icons/daggy.svg")
set(CPACK_IFW_PACKAGE_WIZARD_STYLE "Modern")
set(CPACK_IFW_TARGET_DIRECTORY "@ApplicationsDirX64@/${CPACK_PACKAGE_INSTALL_DIRECTORY}")
set(CPACK_IFW_PACKAGE_STYLE_SHEET ${CMAKE_CURRENT_LIST_DIR}/installer.qss)
set(CPACK_IFW_PACKAGE_TITLE_COLOR "#007A5C")
set(CPACK_IFW_PACKAGE_NAME ${CPACK_PACKAGE_NAME})

set(CPACK_COMPONENTS_ALL application devel)

if(PACKAGE_DEPS)
    include(package_deps)
    set(CPACK_COMPONENTS_ALL ${CPACK_COMPONENTS_ALL} deps)
endif()

IF(${CPACK_SYSTEM_NAME} MATCHES Windows)
    IF(CMAKE_CL_64)
      SET(CPACK_SYSTEM_NAME win64)
    ELSE(CMAKE_CL_64)
      SET(CPACK_SYSTEM_NAME win32)
    ENDIF(CMAKE_CL_64)
ELSEIF(${CPACK_SYSTEM_NAME} MATCHES Linux)
  IF(${CMAKE_CXX_FLAGS})
    STRING(REGEX MATCH "m32" ARCH_FLAG ${CMAKE_CXX_FLAGS})
    if(ARCH_FLAG MATCHES "m32")
      SET(CPACK_SYSTEM_NAME linux32)
      SET(CPACK_DEBIAN_PACKAGE_ARCHITECTURE i386)
      SET(CPACK_RPM_PACKAGE_ARCHITECTURE i386)
    ELSE()
      SET(CPACK_SYSTEM_NAME linux64)
    ENDIF()
  ELSE()
    SET(CPACK_SYSTEM_NAME linux)
  ENDIF()
ELSEIF(${CPACK_SYSTEM_NAME} MATCHES Darwin)
  SET(CPACK_SYSTEM_NAME macos)
ENDIF()

set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_SYSTEM_NAME}-${CPACK_PACKAGE_VERSION}")

include(CPack)
include(CPackIFW)

cpack_add_component_group(Daggy 
                          DISPLAY_NAME "Daggy"
                          DESCRIPTION "Daggy components"
                          EXPANDED)

cpack_add_component(application
                    DISPLAY_NAME "Daggy Console"
                    DESCRIPTION "Daggy console application"
                    GROUP Daggy
                    )
cpack_add_component(devel
                    DISPLAY_NAME "Daggy-devel"
                    DESCRIPTION "Daggy devel lib"
                    GROUP Daggy
                    DISABLED)

if(PACKAGE_DEPS)
    cpack_add_component(deps
                        DISPLAY_NAME "Daggy-deps"
                        DESCRIPTION "Daggy deps"
                        GROUP Daggy
                        HIDDEN
                        REQUIRED)
endif()

cpack_ifw_configure_component_group(Daggy
                                    FORCED_INSTALLATION REQUIRES_ADMIN_RIGHTS
                                    NAME Daggy
                                    DISPLAY_NAME Daggy components
                                    SCRIPT ${CMAKE_CURRENT_LIST_DIR}/installscript.qs
                                    LICENSES MIT ${CMAKE_CURRENT_SOURCE_DIR}/../LICENSE
                                    )
