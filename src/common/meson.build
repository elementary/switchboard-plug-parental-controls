common_files_minimal = files(
    'Utils.vala',
)

configuration_data = configuration_data()
configuration_data.set('DAEMON_CONF_DIR', daemon_conf_dir)

common_files_minimal += configure_file(
    input: 'Constants.vala.cmake',
    output: '@BASENAME@',
    configuration: configuration_data
)

common_files = common_files_minimal
common_files += files(
    'PAM/Writer.vala',
    'PAM/Token.vala',
    'PAM/Reader.vala'
)
