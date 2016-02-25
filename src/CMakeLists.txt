find_package (PkgConfig)

# Add all your dependencies to the list below
pkg_check_modules (DEPS REQUIRED gthread-2.0 gtk+-3.0 switchboard-2.0 granite polkit-gobject-1 accountsservice)

add_definitions (${DEPS_CFLAGS})
link_directories (${DEPS_LIBRARY_DIRS})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.22.0" MINIMUM)

include (ValaPrecompile)
# Add all your vala files and requires packages to the List below to include them in the build
vala_precompile (VALA_C ${CMAKE_PROJECT_NAME}
    Plug.vala
    Widgets/UserList.vala
    Widgets/UserItem.vala
    Widgets/ControlPage.vala
    Widgets/GeneralBox.vala
    Widgets/InternetBox.vala
    Widgets/AppsBox.vala
    Widgets/AppChooser.vala
    Widgets/WeekSpinBox.vala
    shared/Vars.vala
    shared/PAMControl.vala
    shared/Utils.vala
    ${CMAKE_CURRENT_BINARY_DIR}/config.vala
PACKAGES
    gtk+-3.0
    posix
    accountsservice
    polkit-gobject-1
    switchboard-2.0
    granite
OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi/
    --thread
)

add_subdirectory (cli)
add_subdirectory (client)
add_subdirectory (daemon)

add_library (${CMAKE_PROJECT_NAME} MODULE ${VALA_C})
target_link_libraries (${CMAKE_PROJECT_NAME} ${DEPS_LIBRARIES}) 

# Installation
install (TARGETS ${CMAKE_PROJECT_NAME} DESTINATION ${PKGDATADIR})

