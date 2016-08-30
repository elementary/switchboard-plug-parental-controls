find_package (PkgConfig)

pkg_check_modules (CLIENT_DEPS REQUIRED glib-2.0 gio-2.0 polkit-gobject-1 gtk+-3.0)
add_definitions (${CLIENT_DEPS_CFLAGS})
link_directories (${CLIENT_DEPS_LIBRARY_DIRS})

set (CLIENT_EXEC_NAME pantheon-parental-controls-client)

vala_precompile (VALA_C ${CLIENT_EXEC_NAME}
    Client.vala
    AppUnavailableDialog.vala
    ${CMAKE_SOURCE_DIR}/src/shared/Vars.vala
    ${CMAKE_SOURCE_DIR}/src/shared/Utils.vala
PACKAGES
    posix
    polkit-gobject-1
    accountsservice
    gio-2.0
    gtk+-3.0
OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi/
    --thread
)

add_executable (${CLIENT_EXEC_NAME} ${VALA_C})
target_link_libraries (${CLIENT_EXEC_NAME} ${DEPS_LIBRARIES}) 

# Installation
install (TARGETS ${CLIENT_EXEC_NAME} RUNTIME DESTINATION bin)
install (TARGETS ${EXEC_MONITOR_NAME} DESTINATION ${CMAKE_INSTALL_LIBDIR})