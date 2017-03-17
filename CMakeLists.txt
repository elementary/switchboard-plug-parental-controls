# This a sample CMakeLists.txt for compiling plug for Switchboard
# http://elementaryos.org/docs/developer-guide/cmake 

cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.8)

# Set the Name of the plug, should be an executable command, lowercase, no spaces 
set (PLUGNAME "pantheon-parental-controls")
# Set the Category of the Plug, one of:
# personal, hardware, network, system
set (PLUGCATEGORY "system")
# Set the Title to use for the Plug in the Overview and in the Titlebar
set (PLUGTITLE "Parental Control")
# Set the version for the plug
set (VERSION "0.1.3")

# Set the Name of the plug, should be an executable command, lowercase, no spaces 

# When final switch to: switchboard-plug-parental-controls
project (${PLUGNAME})

#########################################################
# Only alter stuff below if you know what you are doing #
#########################################################

include (GNUInstallDirs)
set (DATADIR "${CMAKE_INSTALL_FULL_LIBDIR}/switchboard")
set (PKGDATADIR "${DATADIR}/${PLUGCATEGORY}/${CMAKE_PROJECT_NAME}")
set (GETTEXT_PACKAGE "${CMAKE_PROJECT_NAME}-plug")

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Configure file
configure_file (${CMAKE_SOURCE_DIR}/config.vala.cmake ${CMAKE_BINARY_DIR}/src/config.vala)
configure_file (${CMAKE_SOURCE_DIR}/src/shared/Constants.vala.cmake ${CMAKE_SOURCE_DIR}/src/shared/Constants.vala)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

option (ENABLE_DAEMON_STARTUP "Enable starting daemon on system startup" TRUE)

# Add 'make dist' command for creating release tarball
set (CPACK_PACKAGE_VERSION ${VERSION})
set (CPACK_SOURCE_GENERATOR "TGZ")
set (CPACK_SOURCE_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-${CPACK_PACKAGE_VERSION}")
set (CPACK_SOURCE_IGNORE_FILES "/build/;/.bzr/;/.bzrignore;~$;${CPACK_SOURCE_IGNORE_FILES}")
include (CPack)
add_custom_target (dist COMMAND ${CMAKE_MAKE_PROGRAM} package_source)

# Comment this out to enable C compiler warnings
add_definitions (-w)

# Traslation stuff
add_subdirectory (po)

add_subdirectory (data)
add_subdirectory (src)
