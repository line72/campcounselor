ui_files = files(
  'ui/ui.blp',
  'ui/headerbar.blp',
  'ui/album.blp'
)

blueprints = custom_target(
  'blueprints',
  input: ui_files,
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
  install: true,
  install_dir: pkgdatadir
)
