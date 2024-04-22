sources = files(
  'Album.vala',
  'AlbumEditComment.vala',
  'AlbumListItem.vala',
  'AlbumListModel.vala',
  'AlbumSorter.vala',
  'Application.vala',
  'Bandcamp.vala',
  'BandcampDownloader.vala',
  'Database.vala',
  'DateUtils.vala',
  'ImageCache.vala',
  'MediaBar.vala',
  'MediaPlayer.vala',
  'MessageBoard.vala',
  'MainWindow.vala',
  'Observer.vala',
  'SetupDialog.vala',
  'SettingsManager.vala'
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
  gui_app: true,
  install: true
)
