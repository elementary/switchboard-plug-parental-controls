plug_files = files(
    'MainView.vala',
    'Plug.vala',
    'Views/AppsView.vala',
    'Views/TimeLimitView.vala',
    'Views/InternetView.vala',
    'Widgets/UserList.vala',
    'Widgets/UserItem.vala',
    'Widgets/ControlPage.vala',
    'Widgets/AppChooser.vala',
    'Widgets/AppRow.vala'
)

switchboard_dep = dependency('switchboard-2.0')
switchboard_plugsdir = switchboard_dep.get_pkgconfig_variable('plugsdir', define_variable: ['libdir', libdir])

shared_module(
    meson.project_name(),
    plug_files,
    common_files,
    dependencies: [
        accountsservice_dep,
        glib_dep,
        gio_dep,
        gobject_dep,
        granite_dep,
        gtk_dep,
        hdy_dep,
        polkit_dep,
        switchboard_dep,
        posix_dep
    ],
    install: true,
    install_dir : join_paths(switchboard_plugsdir, 'system')
)
