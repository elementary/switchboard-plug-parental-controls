daemon_files = files(
    'UserConfig.vala',
    'SessionManager.vala',
    'SessionHandler.vala',
    'Server.vala',
    'RestrictionController.vala',
    'Restriction.vala',
    'Process.vala',
    'Interfaces.vala',
    'exec-monitor.c',
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
        gobject_dep,
        gee_dep,
        polkit_dep,
        posix_dep,
        meson.get_compiler('vala').find_library('exec-monitor', dirs: join_paths(meson.source_root(), 'vapi'))
    ],
    install: true,
    install_dir : daemon_path
)
