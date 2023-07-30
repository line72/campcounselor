app_resources = gnome.compile_resources(
  app_id,
  app_id + '.gresource.xml',
  gresource_bundle: true,
  source_dir: '.',
  install: true,
  install_dir: pkgdatadir
)

schemas_dir = get_option('prefix') / get_option('datadir') / 'glib-2.0' / 'schemas'
settings_schemas = [ 'net.line72.campcounselor.gschema.xml' ]

install_data(settings_schemas, install_dir: schemas_dir)

install_data(
  'net.line72.campcounselor-icon.png',
  install_dir: join_paths(datadir, 'icons', 'hicolor', '512x512', 'apps'),
)

install_data(
  'net.line72.campcounselor.desktop',
  install_dir: join_paths(datadir, 'applications'),
)

# flatpak
# Localize a MetaInfo file and install it
i18n = import('i18n')

# NOTE: Remember to add the XML file to POTFILES.in!
metainfo_file = 'net.line72.campcounselor.metainfo.xml'
i18n.merge_file(
  input:  metainfo_file,
  output: 'net.line72.campcounselor.metainfo.xml',
  type: 'xml',
  po_dir: join_paths (meson.source_root(), 'po'),
  install: true,
  install_dir: join_paths (get_option ('datadir'), 'metainfo')
)
