vala_precompile (VALA_C parental-control-cli
    main.vala
    ${CMAKE_SOURCE_DIR}/src/shared/Utils.vala
    ${CMAKE_SOURCE_DIR}/src/shared/PAMControl.vala
PACKAGES
    posix
    accountsservice
    polkit-gobject-1
    granite
    gtk+-3.0
    gio-2.0
OPTIONS
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/../../vapi/
    --thread  
)

add_executable (parental-control-daemon ${VALA_C})
target_link_libraries (parental-control-daemon ${DEPS_LIBRARIES}) 

# Installation
install (TARGETS parental-control-daemon RUNTIME DESTINATION bin)
