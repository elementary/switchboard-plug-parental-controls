configure_file (org.pantheon.switchboard.parental-controls.policy.cmake ${CMAKE_CURRENT_BINARY_DIR}/data/org.pantheon.switchboard.parental-controls.policy)
configure_file (pantheon-parental-controls-daemon.service.cmake ${CMAKE_CURRENT_BINARY_DIR}/pantheon-parental-controls-daemon.service)

install (FILES ${CMAKE_CURRENT_BINARY_DIR}/data/org.pantheon.switchboard.parental-controls.policy DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/polkit-1/actions/)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/pantheon-parental-controls-daemon.service DESTINATION share/dbus-1/services/)
install (FILES pantheon-parental-controls-daemon.desktop DESTINATION share/applications)