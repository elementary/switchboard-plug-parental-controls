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

gettext_declaration = configure_file(
    configuration: configuration_data,
    input: 'screentime-limits.policy.in.in',
    output: '@BASENAME@'
)

i18n.merge_file(
    input: gettext_declaration,
    output: gettext_name + '.policy',
    po_dir: meson.source_root() / 'po' / 'extra',
    install: true,
    install_dir: polkit_actiondir
)

configure_file(
    input: 'org.pantheon.ParentalControls.service.in',
    output: 'org.pantheon.ParentalControls.service',
    configuration: configuration_data,
    install_dir: dbus_dep.get_pkgconfig_variable('system_bus_services_dir', define_variable: ['datadir', datadir])
)

configure_file(
    input: 'pantheon-parental-controls-client.desktop.in',
    output: 'pantheon-parental-controls-client.desktop',
    configuration: configuration_data,
    install_dir: join_paths(datadir, 'applications')
)

install_data(
    'org.pantheon.ParentalControls.conf',
    install_dir: join_paths(datadir, 'dbus-1', 'system.d')
)

install_data(
    'daemon.conf',
    install_dir: daemon_conf_dir
)

i18n.merge_file(
    input: 'screentime-limits.metainfo.xml.in',
    output: gettext_name + '.metainfo.xml',
    po_dir: meson.source_root() / 'po' / 'extra',
    type: 'xml',
    install: true,
    install_dir: datadir / 'metainfo',
)
