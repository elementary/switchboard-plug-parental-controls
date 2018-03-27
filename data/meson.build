configuration_data = configuration_data()
configuration_data.set('DAEMON_PATH', join_paths(daemon_path, daemon_name))
configuration_data.set('GETTEXT_PACKAGE', gettext_name)
configuration_data.set('CLIENT_PATH', client_path)

dbus_dep = dependency('dbus-1')

configure_file(
    input: 'pantheon-parental-controls.service.in',
    output: '@BASENAME@',
    configuration: configuration_data,
    install_dir: join_paths(get_option('libdir'),'systemd', 'system')
)

configure_file(
    input: 'org.pantheon.switchboard.parental-controls.policy.in',
    output: '@BASENAME@',
    configuration: configuration_data,
    install_dir: polkit_dep.get_pkgconfig_variable('policydir')
)

configure_file(
    input: 'org.pantheon.ParentalControls.service.in',
    output: '@BASENAME@',
    configuration: configuration_data,
    install_dir: dbus_dep.get_pkgconfig_variable('system_bus_services_dir')
)

install_data(
    'org.pantheon.ParentalControls.conf',
    install_dir: join_paths(dbus_dep.get_pkgconfig_variable('sysconfdir'), 'dbus-1', 'system.d')
)

install_data(
    'daemon.conf',
    install_dir: daemon_conf_dir
)

install_data(
    'pantheon-parental-controls-client.desktop',
    install_dir: join_paths(get_option('datadir'), 'applications')
)
