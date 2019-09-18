configuration_data = configuration_data()
configuration_data.set('DAEMON_PATH', join_paths(daemon_path, daemon_name))
configuration_data.set('GETTEXT_PACKAGE', gettext_name)
configuration_data.set('CLIENT_PATH', join_paths(client_path, client_name))

dbus_dep = dependency('dbus-1')

systemdunitdir = get_option('systemdunitdir')
if systemdunitdir == ''
    systemdunitdir = systemd_dep.get_pkgconfig_variable('systemdsystemunitdir')
endif

configure_file(
    input: 'pantheon-parental-controls.service.in',
    output: 'pantheon-parental-controls.service',
    configuration: configuration_data,
    install_dir: systemdunitdir
)

configure_file(
    input: 'org.pantheon.switchboard.parental-controls.policy.in',
    output: 'org.pantheon.switchboard.parental-controls.policy',
    configuration: configuration_data,
    install_dir: polkit_dep.get_pkgconfig_variable('policydir')
)

configure_file(
    input: 'org.pantheon.ParentalControls.service.in',
    output: 'org.pantheon.ParentalControls.service',
    configuration: configuration_data,
    install_dir: dbus_dep.get_pkgconfig_variable('system_bus_services_dir')
)

configure_file(
    input: 'pantheon-parental-controls-client.desktop.in',
    output: 'pantheon-parental-controls-client.desktop',
    configuration: configuration_data,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

install_data(
    'org.pantheon.ParentalControls.conf',
    install_dir: join_paths(dbus_dep.get_pkgconfig_variable('sysconfdir'), 'dbus-1', 'system.d')
)

install_data(
    'daemon.conf',
    install_dir: daemon_conf_dir
)

i18n.merge_file(
    input: 'io.elementary.switchboard.parental-controls.appdata.xml.in',
    output: 'io.elementary.switchboard.parental-controls.appdata.xml',
    po_dir: join_paths(meson.source_root (), 'po', 'extra'),
    install_dir: join_paths(get_option('datadir'), 'metainfo'),
    install: true
)
