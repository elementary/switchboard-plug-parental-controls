find_package (PkgConfig)

pkg_check_modules (CLI_DEPS REQUIRED glib-2.0 gio-2.0 polkit-gobject-1 accountsservice)
add_definitions (${CLI_DEPS_CFLAGS})
link_directories (${CLI_DEPS_LIBRARY_DIRS})

set (CLI_EXEC_NAME pantheon-parental-controls-cli)

vala_precompile (VALA_C ${CLI_EXEC_NAME}
    Application.vala
    FileReader.vala
    PAMWriter.vala
    ${CMAKE_SOURCE_DIR}/src/shared/Vars.vala
    ${CMAKE_SOURCE_DIR}/src/shared/Utils.vala
PACKAGES
    gio-2.0
    accountsservice
    polkit-gobject-1
    posix
OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi/
    --thread  
)

add_executable (${CLI_EXEC_NAME} ${VALA_C})
target_link_libraries (${CLI_EXEC_NAME} ${DEPS_LIBRARIES}) 

# Installation
install (TARGETS ${CLI_EXEC_NAME} RUNTIME DESTINATION bin)