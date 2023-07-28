sources = files(
  'Application.vala',
  'MainWindow.vala',
  'Bandcamp.vala',
  'Album.vala',
  'AlbumEditComment.vala',
  'AlbumListItem.vala',
  'AlbumListModel.vala',
  'AlbumSorter.vala',
  'DateUtils.vala',
  'ImageCache.vala',
  'Database.vala'
)

c_args = [
  '-include', 'config.h',
  '-DLOCALEDIR="@0@"'.format(localedir),
]

vala_args = [
  '--vapidir', vapi_dir,
  '--pkg', 'config',
]


executable(
  'campcounselor',
  [sources,  app_resources],
  dependencies: dependencies,
  c_args: c_args,
  vala_args: vala_args,
  include_directories: config_h_dir,
  install: true
)
