project(
  'net.line72.campcounselor',
  'vala', 'c',
  version: '0.0.1',
  license: 'GPLv3+'
)

gnome = import('gnome')

app_id = 'net.line72.campcounselor'

prefix = get_option('prefix')  # should be /usr
bindir = get_option('bindir')  # should be bin
datadir = get_option('datadir')  # should be /usr/share
pkgdatadir = join_paths(prefix, datadir, meson.project_name())
localedir = join_paths(prefix, get_option('localedir'))

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gtk4'),
    dependency('libadwaita-1', version: '>= 1.1.0'),
    dependency('libsoup-3.0'),
    dependency('json-glib-1.0'),
    dependency('gee-0.8')
]

subdir('data')
subdir('src')
