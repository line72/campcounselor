project(
  'net.line72.campcounselor',
  'vala', 'c',
  version: '0.99.9',
  license: 'GPLv3+'
)

gnome = import('gnome')

app_id = 'net.line72.campcounselor'

prefix = get_option('prefix')  # should be /usr
bindir = get_option('bindir')  # should be bin
datadir = get_option('datadir')  # should be /usr/share
pkgdatadir = join_paths(prefix, datadir, meson.project_name())
localedir = join_paths(prefix, get_option('localedir'))
vapi_dir = meson.project_source_root() / 'vapi'
config_h_dir = include_directories('.')

# Configuration
conf = configuration_data()
conf.set_quoted('APP_ID', app_id)
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('G_LOG_DOMAIN', meson.project_name())
conf.set_quoted('DATADIR', prefix / datadir)
conf.set_quoted('LOCALEDIR', localedir)
conf.set_quoted('LIBEXECDIR', get_option('prefix') / get_option('libexecdir'))
conf.set_quoted('PACKAGE_NAME', meson.project_name())
conf.set_quoted('PACKAGE_STRING', meson.project_name())
conf.set_quoted('PACKAGE_VERSION', meson.project_version())
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('SOURCE_DIR', meson.source_root ())
configure_file(output: 'config.h', configuration: conf)


dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gtk4'),
    dependency('libadwaita-1', version: '>= 1.1.0'),
    dependency('libsoup-3.0'),
    dependency('json-glib-1.0'),
    dependency('gee-0.8'),
    dependency('libgda-6.0'),
    dependency('libxml-2.0'),
    dependency('libsecret-1')
]

subdir('data')
subdir('src')

gnome.post_install(
  gtk_update_icon_cache: true,
  glib_compile_schemas: true,
  update_desktop_database: true,
)
