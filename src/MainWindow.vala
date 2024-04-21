/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	[GtkTemplate (ui = "/net/line72/campcounselor/ui/mainwindow.ui")]
	public class MainWindow : Gtk.ApplicationWindow {
		/* Create the window actions. */
		const ActionEntry[] actions = {
			/*{ "action name", cb to connect to "activate" signal, parameter type,
			  initial state, cb to connect to "change-state" signal } */
			{ "filterby", filterby_cb, "s", "'all'" },
			{ "sortby", sortby_cb, "s", "'artist_asc'" }
		};

		[GtkChild( name = "main-vbox" )]
		private unowned Gtk.Box vbox;

		[GtkChild( name = "refresh-progress" )]
		private unowned Gtk.ProgressBar progress_bar;

		[GtkChild( name = "main-scrolled-window" )]
		private unowned Gtk.ScrolledWindow scrolled_window;

		[GtkChild( name = "media-player-action-bar" )]
		private unowned MediaBar media_bar;
		
		private ImageCache image_cache = new ImageCache();
		private AlbumListModel albums_list_model = null;
		private Gtk.FilterListModel search_model = null;
		private Gtk.FilterListModel filtered_model = null;
		private Gtk.SortListModel sorted_model = null;
		private AlbumSorter sorter = null;
		private Settings settings = null;
		private Database db = null;
	
		public MainWindow (CampCounselor.Application application) throws GLib.Error {
			Object (
				title: "Camp Counselor",
				application: application,
				resizable: true
				);

			var fan_id = this.settings.get_string("bandcamp-fan-id");
			if (fan_id == null || fan_id == "") {
				var d = new SetupDialog(this);
				d.close_request.connect((response) => {
						open_database();
						return false;
					});
				d.show();
			} else {
				open_database();
			}
		}

		construct {
			set_default_size(600, 800);

			// // TMO
			// BandcampDownloader.parse_tracks.begin("https://bloodytyrantband.bandcamp.com/album/myths-of-the-islands", (obj, res) => {
			// 	var tracks = BandcampDownloader.parse_tracks.end(res);
			// 	if (tracks != null) {
			// 		stdout.printf("parsed tracks\n");
			// 		foreach (BandcampDownloader.Track track in tracks) {
			// 			stdout.printf(@"$(track.num) - $(track.name): $(track.url)\n");
			// 		}
			// 		// get the first track and play it
			// 		BandcampDownloader.Track track1 = tracks.get(0);
					
			// 		Gst.Element playbin = Gst.ElementFactory.make("playbin", "audio_player");
			// 		Gst.Bus bus = playbin.get_bus();
			// 		bus.add_watch(0, (bus1, message) => {
			// 				stdout.printf(@"got bus message: $(message.type.get_name())\n");
			// 				switch (message.type) {
			// 				  // case Gst.MessageType.STATE_CHANGED:
			// 				  // 	  // we don't have to listen to this, but if we do
			// 				  // 	  // we need to ONLY react to ones from the correct src
			// 				  // 	  //  not other internal ones. Reacting to the internal
			// 				  // 	  //  ones will break the pipeline. (this doesn't seem
			// 				  // 	  //  to be true)
			// 				  // 	  Gst.Element src = (Gst.Element)message.src;  // Get the source of the message
			// 				  // 	  if (src == playbin) {
			// 				  // 		  Gst.State old_state;
			// 				  // 		  Gst.State new_state;
			// 				  // 		  Gst.State pending_state;
									  
			// 				  // 		  message.parse_state_changed (out old_state, out new_state, out pending_state);
			// 				  // 		  stdout.printf("Pipeline state changed from %s to %s:\n",
			// 				  // 						Gst.Element.state_get_name (old_state),
			// 				  // 						Gst.Element.state_get_name (new_state));
			// 				  // 	  }
			// 				  // 	  break;
			// 				  case Gst.MessageType.EOS: // end of stream
			// 					  stdout.printf("Song finished\n");
			// 					  playbin.set_state(Gst.State.NULL);  // Reset pipeline state
			// 					  break;
 			// 				  case Gst.MessageType.ERROR:
			// 					  Error err;
			// 					  string debug;
			// 					  message.parse_error (out err, out debug);
			// 					  stdout.printf(@"Error playing: $(debug)\n");
			// 					  break;
			// 				  default:
			// 					  break;
			// 				}

			// 				return true; // return true to keep listening
			// 			});
						
			// 		playbin.set("uri", track1.url);
			// 		stdout.printf("setting to playing\n");
			// 		playbin.set_state(Gst.State.PLAYING);
			// 		stdout.printf("playing\n");
					
			// 	 } else {
			// 		stdout.printf("No tracks?\n");
			// 	}
			// });
			
			try {
				var settings_mgr = SettingsManager.get_instance();
				this.settings = settings_mgr.settings;
				
				var builder = new Gtk.Builder.from_resource("/net/line72/campcounselor/ui/headerbar.ui");
				var headerbar = (Gtk.HeaderBar)builder.get_object("headerbar");
				
				set_titlebar(headerbar);
				add_action_entries(actions, this);

				// hook up a search entry
				var search_entry = (Gtk.SearchEntry)builder.get_object("search_entry");
				search_entry.search_changed.connect(() => {
						if (search_entry.get_text() == "") {
							this.search_model.set_filter(new Gtk.EveryFilter());
						} else {
							// create a multi OR filter
							var multi = new Gtk.AnyFilter();

							// search artist
							var exp_artist = new Gtk.PropertyExpression(typeof (Album), null, "artist");
							var f_artist = new Gtk.StringFilter(exp_artist);
							f_artist.set_search(search_entry.get_text());

							// search album
							var exp_album = new Gtk.PropertyExpression(typeof (Album), null, "album");
							var f_album = new Gtk.StringFilter(exp_album);
							f_album.set_search(search_entry.get_text());

							multi.append(f_artist);
							multi.append(f_album);
							
							this.search_model.set_filter(multi);
						}
					});
				
				// set the appropriate action states
				Action action = lookup_action("filterby");
				action.change_state(settings_mgr.enum_to_filterby(this.settings.get_enum("filter-by")));
				action = lookup_action("sortby");
				action.change_state(settings_mgr.enum_to_sortby(this.settings.get_enum("sort-by")));
				
				this.albums_list_model = new AlbumListModel();

				// Add a search
				this.search_model = new Gtk.FilterListModel(albums_list_model, new Gtk.EveryFilter());
				// Then filter
				this.filtered_model = new Gtk.FilterListModel(this.search_model, build_filter(settings_mgr.enum_to_filterby(this.settings.get_enum("filter-by"))));
				// Then sort
				this.sorter = new AlbumSorter(this.settings.get_enum("sort-by"));
				this.sorted_model = new Gtk.SortListModel(this.filtered_model, this.sorter);

				var main_window = this;
				var factory = new Gtk.SignalListItemFactory();

				factory.setup.connect((f, itm) => {
						Gtk.ListItem i = itm as Gtk.ListItem;
					
						AlbumListItem list_item = new AlbumListItem();

						i.set_child(list_item);
					});
				factory.bind.connect((f, itm) => {
						Gtk.ListItem i = itm as Gtk.ListItem;

						AlbumListItem li = i.get_child() as AlbumListItem;
						Album a = i.get_item() as Album;

						// check for a cached item
						if (image_cache.exists(a.bandcamp_id)) {
							li.album_cover.file = image_cache.get_path(a.bandcamp_id);
						} else {
							this.image_cache.get_image.begin(
								a.thumbnail_url, a.bandcamp_id,
								(obj, res) => {
									try {
										var p = image_cache.get_image.end(res);
										li.album_cover.file = p;
									} catch (Error e) {
										stdout.printf("Error downloading cache image %s\n", e.message);
									}
								});
						}

						// star rating
						li.set_stars(a.rating);
					
						li.album_band.label = a.artist;
						li.album_title.label = a.album;
						li.album_uri.uri = a.url;
						li.edit_comment_handler_id = li.edit_comment.clicked.connect(() => {
								stdout.printf(@"Clicked on $(a.artist)\n");
								var d = new AlbumEditComment(a, main_window);

								d.response.connect((response) => {
										if (response == Gtk.ResponseType.OK) {
											a.comment = d.comment.buffer.text;
											a.rating = (int)d.rating.value;
											stdout.printf(a.comment + "\n");
											// save
											try {
												this.db.update_album(a);
												li.set_stars(a.rating);
											} catch (GLib.Error e) {
												stdout.printf("error saving...\n");
											}
										}
										d.destroy();
									});
								d.show();
							});

						li.play_handler_id = li.play.clicked.connect(() => {
								stdout.printf(@"Clicked on $(a.artist)\n");
								BandcampDownloader.parse_tracks.begin(a.url, (obj, res) => {
										var tracks = BandcampDownloader.parse_tracks.end(res);
										stdout.printf("parsed tracks\n");
										if (tracks != null) {
											MediaPlayer mp = MediaPlayer.get_instance();
											mp.set_tracks(tracks, li.album_cover.file);
											mp.play();
											media_bar.reveal();
										}
									});

							});
					});
				factory.unbind.connect((f, itm) => {
						Gtk.ListItem i = itm as Gtk.ListItem;

						AlbumListItem li = i.get_child() as AlbumListItem;

						li.edit_comment.disconnect(li.edit_comment_handler_id);
						li.edit_comment_handler_id = 0;

						li.play.disconnect(li.play_handler_id);
						li.play_handler_id = 0;
					});
			
				var selection = new Gtk.NoSelection(this.sorted_model);

				var grid_view = new Gtk.GridView(selection, factory);
				grid_view.set_hscroll_policy(Gtk.ScrollablePolicy.NATURAL);
				grid_view.set_vscroll_policy(Gtk.ScrollablePolicy.NATURAL);
			
				scrolled_window.set_child(grid_view);
			} catch (GLib.Error e) {
				stdout.printf("!!ERROR: %s\n", e.message);
			}
		}

		public void refresh() {
			var bandcamp = new BandCamp(this.settings.get_string("bandcamp-url"));
			var fan_id = this.settings.get_string("bandcamp-fan-id");

			refresh_bandcamp(bandcamp, fan_id, true);
		}

		private void open_database() {
			this.db = new Database();
			this.db.open.begin(
				(obj, res) => {
					try {
						// we don't care about the result, unless
						// it throws an exception
						this.db.open.end(res);

						albums_list_model.set_database(this.db);
						albums_list_model.reset_albums();
						
						var bandcamp = new BandCamp(this.settings.get_string("bandcamp-url"));

						var fan_id = this.settings.get_string("bandcamp-fan-id");
						refresh_bandcamp(bandcamp, fan_id);

					} catch (GLib.Error e) {
						var d = new Gtk.AlertDialog(@"Unable to open database. $(e.message)");
						d.modal = true;
						d.choose.begin(this, null, (obj, res) => {
								try {
									d.choose.end(res);
								} catch (GLib.Error e) {
								}
							});
					}
				});
		}
	
		void refresh_bandcamp(BandCamp bandcamp, string fan_id, bool force = false) {
			if (this.db == null)
				return;
			
			var last_refresh = this.db.last_refresh();
			var now = new DateTime.now_utc();
			var diff = now.difference(last_refresh); // diff is in μs
			if (force || diff > 3.6e+9 * this.settings.get_uint("refresh-period")) { // refresh-period is hours

				// start pulsing the progress bar
				this.progress_bar.visible = true;
				var time = new TimeoutSource(200);

				time.set_callback(() => {
						this.progress_bar.pulse();
						return true;
					});
				time.attach(null);

				
				// fetch collection and wishlist in the background
				bandcamp.fetch_collection_async.begin(
					fan_id, (obj, res) => {
						var fetched_albums = bandcamp.fetch_collection_async.end(res);

						this.db.insert_new_albums.begin(fetched_albums, (obj, res) => {
								try {
									this.db.insert_new_albums.end(res);
									this.albums_list_model.reset_albums();
								} catch (ThreadError e) {
									stdout.printf("Error inserting new albums from collection: %s\n", e.message);
								}

								// now the wishlist
								bandcamp.fetch_wishlist_async.begin(
									fan_id, (obj, res) => {
										var fetched_wishlist_albums = bandcamp.fetch_collection_async.end(res);
										
										this.db.insert_new_albums.begin(fetched_wishlist_albums, (obj, res) => {
												try {
													this.db.insert_new_albums.end(res);
													this.albums_list_model.reset_albums();
										
													// detach the timout
													time.destroy();
										
													// hide the progress bar
													this.progress_bar.visible = false;
												} catch (ThreadError e) {
													stdout.printf("Error inserting new albums from wishlist: %s\n", e.message);
												}
											});
									});
							});

					});
				this.db.update_last_refresh(now);
			}
		}

		void filterby_cb(SimpleAction action, Variant? parameter) {
			var filter = build_filter(parameter.get_string(null));
			this.filtered_model.set_filter(filter);

			try {
				var settings_mgr = SettingsManager.get_instance();
				this.settings.set_enum("filter-by", settings_mgr.filterby_to_enum(parameter.get_string(null)));
			} catch (GLib.Error e) {
				stdout.printf(@"MainWindow.filterby_cb: Unable to build SettingsManager: $(e.message)\n");
			}
			action.set_state(parameter);
		}

		Gtk.Filter build_filter(string s) {
			if (s == "purchased") {
				var exp1 = new Gtk.PropertyExpression(typeof (Album), null, "purchased");
				return new Gtk.BoolFilter(exp1);
			} else if (s == "wishlist") {
				var exp1 = new Gtk.PropertyExpression(typeof (Album), null, "purchased");
				var wishlist_filter = new Gtk.BoolFilter(exp1);
				wishlist_filter.set_invert(true);

				return wishlist_filter;
			} else {
				return new Gtk.EveryFilter();
			}
		}

		void sortby_cb(SimpleAction action, Variant? parameter) {
			var s = parameter.get_string(null);
		
			if (s == "artist_asc") {
				this.sorter.sortType = AlbumSorter.AlbumSortType.TITLE_ASC;
			} else if (s == "artist_desc") {
				this.sorter.sortType = AlbumSorter.AlbumSortType.TITLE_DESC;
			} else if (s == "rating_asc") {
				this.sorter.sortType = AlbumSorter.AlbumSortType.RATING_ASC;
			} else if (s == "rating_desc") {
				this.sorter.sortType = AlbumSorter.AlbumSortType.RATING_DESC;
			} else if (s == "updated_asc") {
				this.sorter.sortType = AlbumSorter.AlbumSortType.UPDATED_ASC;
			} else if (s == "updated_desc") {
				this.sorter.sortType = AlbumSorter.AlbumSortType.UPDATED_DESC;
			} else if (s == "created_asc") {
				this.sorter.sortType = AlbumSorter.AlbumSortType.CREATED_ASC;
			} else if (s == "created_desc") {
				this.sorter.sortType = AlbumSorter.AlbumSortType.CREATED_DESC;
			}

			// save this setting
			this.settings.set_enum("sort-by", this.sorter.sortType);
		
			action.set_state(parameter);
		}

	}
}