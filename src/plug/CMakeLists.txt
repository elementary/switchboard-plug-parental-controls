
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
    ${CMAKE_SOURCE_DIR}/src/common/Constants.vala
    ${CMAKE_SOURCE_DIR}/src/common/Utils.vala
    ${CMAKE_SOURCE_DIR}/src/common/PAM/Token.vala
    ${CMAKE_SOURCE_DIR}/src/common/PAM/Reader.vala
    ${CMAKE_SOURCE_DIR}/src/common/PAM/Writer.vala
    ${CMAKE_BINARY_DIR}/src/config.vala
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

add_library (${CMAKE_PROJECT_NAME} MODULE ${VALA_C})
target_link_libraries (${CMAKE_PROJECT_NAME} ${DEPS_LIBRARIES}) 

# Installation
install (TARGETS ${CMAKE_PROJECT_NAME} DESTINATION ${PKGDATADIR})
