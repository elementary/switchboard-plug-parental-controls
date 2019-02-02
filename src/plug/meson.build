plug_files = files(
    'Plug.vala',
    'Widgets/WeekSpinBox.vala',
    'Widgets/UserList.vala',
    'Widgets/UserItem.vala',
    'Widgets/InternetBox.vala',
    'Widgets/GeneralBox.vala',
    'Widgets/ControlPage.vala',
    'Widgets/AppsBox.vala',
    'Widgets/AppChooser.vala',
    'Widgets/AppRow.vala'
)

switchboard_dep = dependency('switchboard-2.0')

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
        polkit_dep,
        switchboard_dep,
        posix_dep
    ],
    install: true,
    install_dir : join_paths(switchboard_dep.get_pkgconfig_variable('plugsdir'), 'system')
)
