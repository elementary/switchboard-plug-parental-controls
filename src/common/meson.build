common_files_minimal = files(
    'Utils.vala',
)

configuration_data = configuration_data()
configuration_data.set('DAEMON_CONF_DIR', daemon_conf_dir)
configuration_data.set('CLIENT_PATH', join_paths(client_path, client_name))
configuration_data.set('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
configuration_data.set('GETTEXT_PACKAGE', meson.project_name())

common_files_minimal += configure_file(
    input: 'Constants.vala.in',
    output: '@BASENAME@',
    configuration: configuration_data
)

common_files = common_files_minimal
common_files += files(
    'PAM/Writer.vala',
    'PAM/Token.vala',
    'PAM/Reader.vala'
)
