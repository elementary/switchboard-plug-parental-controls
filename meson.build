project(
    'screentime-limits',
    'vala', 'c',
    meson_version: '>= 0.57',
    version: '6.0.1'
)

gettext_name = 'io.elementary.settings.' + meson.project_name()
gnome = import('gnome')
i18n = import('i18n')

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    language:'c'
)

add_project_arguments(
    ['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
    language: 'vala'
)

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
libdir = join_paths(prefix, get_option('libdir'))

client_path = join_paths(prefix, get_option('libexecdir'))
client_name = 'pantheon-parental-controls-client'

daemon_path = join_paths(prefix, get_option('bindir'))
daemon_name = 'pantheon-parental-controls-daemon'
daemon_conf_dir = join_paths(get_option('sysconfdir'), 'pantheon-parental-controls')

polkit_dep = dependency('polkit-gobject-1')
polkit_actiondir = polkit_dep.get_pkgconfig_variable('actiondir', define_variable: ['prefix', prefix])

glib_dep = dependency('glib-2.0')
gio_dep = dependency('gio-2.0')
gio_unix_dep = dependency('gio-unix-2.0')
gobject_dep = dependency('gobject-2.0')
granite_dep = dependency('granite-7')
gtk_dep = dependency('gtk4')
gee_dep = dependency('gee-0.8')
flatpak_dep = dependency('flatpak')
malcontent_dep = dependency('malcontent-0')
hdy_dep = dependency('libadwaita-1')
accountsservice_dep = dependency('accountsservice')
systemd_dep = dependency('systemd')
posix_dep = meson.get_compiler('vala').find_library('posix')

subdir('data')
subdir('src')
subdir('po')

gnome.post_install(
  gtk_update_icon_cache: true
)
