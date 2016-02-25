configure_file (org.pantheon.switchboard.parental-controls.policy.cmake ${CMAKE_CURRENT_BINARY_DIR}/data/org.pantheon.switchboard.parental-controls.policy)
configure_file (pantheon-parental-controls.service.cmake ${CMAKE_CURRENT_BINARY_DIR}/pantheon-parental-controls.service)

install (FILES ${CMAKE_CURRENT_BINARY_DIR}/data/org.pantheon.switchboard.parental-controls.policy DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/polkit-1/actions/)
install (FILES org.pantheon.ParentalControls.service DESTINATION share/dbus-1/system-services)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/pantheon-parental-controls.service DESTINATION /lib/systemd/system)
install (FILES org.pantheon.ParentalControls.conf DESTINATION /etc/dbus-1/system.d)
install (FILES pantheon-parental-controls-client.desktop DESTINATION share/applications)