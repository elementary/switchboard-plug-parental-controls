client_files = files(
    'Agent.vala',
    'AppUnavailableDialog.vala'
)

executable(
    client_name,
    client_files,
    common_files_minimal,
    dependencies: [
        accountsservice_dep,
        glib_dep,
        gio_dep,
        gobject_dep,
        granite_dep,
        gtk_dep,
        polkit_dep,
        posix_dep
    ],
    install: true,
    install_dir : client_path
)
