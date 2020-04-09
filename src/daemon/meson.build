daemon_files = files(
    'UserConfig.vala',
    'SessionManager.vala',
    'SessionHandler.vala',
    'Server.vala',
    'RestrictionController.vala',
    'Restriction.vala',
    'AccessControlLists.vala',
    'Interfaces.vala',
    'Daemon.vala',
    'Restrictions/WebRestriction.vala',
    'Restrictions/TimeRestriction.vala',
    'Restrictions/AppRestriction.vala'
)

executable(
    daemon_name,
    daemon_files,
    common_files,
    dependencies: [
        accountsservice_dep,
        glib_dep,
        gio_dep,
        gio_unix_dep,
        gobject_dep,
        gee_dep,
        polkit_dep,
        posix_dep,
    ],
    install: true,
    install_dir : daemon_path
)
