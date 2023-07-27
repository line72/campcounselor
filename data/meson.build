blp_files = files(
  'ui/headerbar.blp',
)

blueprints = custom_target(
  'blueprints',
  input: blp_files,
  output: '.',
  command: [
    find_program('blueprint-compiler'),
    'batch-compile',
    '@OUTPUT@',
    '@CURRENT_SOURCE_DIR@',
    '@INPUT@'
  ]
)

app_resources = gnome.compile_resources(
  app_id,
  app_id + '.gresource.xml',
  gresource_bundle: true,
  dependencies: blueprints,
  source_dir: '.',
  install: true,
  install_dir: pkgdatadir
)

schemas_dir = get_option('prefix') / get_option('datadir') / 'glib-2.0' / 'schemas'
settings_schemas = [ 'net.line72.campcounselor.gschema.xml' ]

install_data(settings_schemas, install_dir: schemas_dir)

# Compile the schemas in the current directory; this is only
# useful for testing
gnome = import('gnome')
gnome.compile_schemas(depend_files: files(settings_schemas))

meson.add_install_script('glib-compile-schemas', schemas_dir)
