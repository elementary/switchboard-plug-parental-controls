project('parental-controls', 'vala', 'c')

gettext_name = meson.project_name() + '-plug'
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


client_path = join_paths(get_option('prefix'), get_option('libexecdir'))
client_name = 'pantheon-parental-controls-client'

daemon_path = join_paths(get_option('prefix'), get_option('bindir'))
daemon_name = 'pantheon-parental-controls-daemon'
daemon_conf_dir = join_paths(get_option('sysconfdir'), 'pantheon-parental-controls')

glib_dep = dependency('glib-2.0')
gio_dep = dependency('gio-2.0')
gobject_dep = dependency('gobject-2.0')
granite_dep = dependency('granite')
gtk_dep = dependency('gtk+-3.0')
gee_dep = dependency ('gee-0.8')
polkit_dep = dependency('polkit-gobject-1')
accountsservice_dep = dependency('accountsservice')
posix_dep = meson.get_compiler('vala').find_library('posix')

subdir('data')
subdir('src')
subdir('po')
