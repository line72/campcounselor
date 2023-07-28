/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

using Config;

public class CampCounselor.MainWindow : Gtk.ApplicationWindow {
	/* Create the window actions. */
	const ActionEntry[] actions = {
		/*{ "action name", cb to connect to "activate" signal, parameter type,
		  initial state, cb to connect to "change-state" signal } */
		{ "filterby", filterby_cb, "s", "'all'" },
		{ "sortby", sortby_cb, "s", "'artist_asc'" }
	};

	private ImageCache image_cache = new ImageCache();
	private AlbumListModel albums_list_model = null;
	private Gtk.FilterListModel filtered_model = null;
	private Gtk.SortListModel sorted_model = null;
	private AlbumSorter sorter = null;
	private Settings settings = null;
	
	public MainWindow (CampCounselor.Application application) {
		Object (
			title: "Camp Counselor",
			application: application,
			resizable: true
			);
	}

	construct {
		set_default_size(600, 800);

		this.settings = get_settings_from_system() ??
			get_settings_from(Config.SOURCE_DIR + "/build/data");
		if (this.settings == null) {
			stdout.printf("SETTINGS IS NULL\n");
		}

		var sort_by = this.settings.get_enum("sort-by");
		stdout.printf("sorting by %d\n", sort_by);
		
		var db = new Database();
		var builder = new Gtk.Builder.from_resource("/net/line72/campcounselor/ui/headerbar.ui");
		var headerbar = (Gtk.HeaderBar)builder.get_object("headerbar");

		set_titlebar(headerbar);
		add_action_entries(actions, this);

		// set the appropriate action states
		Action action = lookup_action("filterby");
		action.change_state(enum_to_filterby(this.settings.get_enum("filter-by")));
		action = lookup_action("sortby");
		action.change_state(enum_to_sortby(this.settings.get_enum("sort-by")));
		
		this.albums_list_model = new AlbumListModel();

		this.filtered_model = new Gtk.FilterListModel(albums_list_model, build_filter(enum_to_filterby(this.settings.get_enum("filter-by"))));

		this.sorter = new AlbumSorter(this.settings.get_enum("sort-by"));
		this.sorted_model = new Gtk.SortListModel(this.filtered_model, this.sorter);
		
		var scrolled_window = new Gtk.ScrolledWindow();
		set_child(scrolled_window);

		try {
			var main_window = this;
			var factory = new Gtk.SignalListItemFactory();

			factory.setup.connect((f, itm) => {
					// stdout.printf("Factory Setup\n");
					
					AlbumListItem list_item = new AlbumListItem();

					itm.set_child(list_item);
				});
			factory.bind.connect((f, itm) => {
					//stdout.printf("Factory Bind\n");
					AlbumListItem li = itm.get_child() as AlbumListItem;
					Album a = itm.get_item() as Album;

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
											db.update_album(a);
											li.set_stars(a.rating);
										} catch (GLib.Error e) {
											stdout.printf("error saving...\n");
										}
									}
									d.destroy();
								});
							d.show();
						});
				});
			factory.unbind.connect((f, itm) => {
					//stdout.printf("Factory Unbind\n");
					AlbumListItem li = itm.get_child() as AlbumListItem;

					li.edit_comment.disconnect(li.edit_comment_handler_id);
					li.edit_comment_handler_id = 0;
				});
			
			var selection = new Gtk.NoSelection(this.sorted_model);

			var grid_view = new Gtk.GridView(selection, factory);
			grid_view.set_hscroll_policy(Gtk.ScrollablePolicy.NATURAL);
			grid_view.set_vscroll_policy(Gtk.ScrollablePolicy.NATURAL);
			
			scrolled_window.set_child(grid_view);
		} catch (GLib.Error e) {
			stdout.printf("!!ERROR: %s\n", e.message);
		}
		
		present ();

		var albums = db.get_albums();
		albums_list_model.set_albums(albums);
		
		var bandcamp = new BandCamp();

		// fetch collection and wishlist in the background
		bandcamp.fetch_collection_async.begin(
			"1057301", (obj, res) => {
				var fetched_albums = bandcamp.fetch_collection_async.end(res);
				// foreach (Album? album in albums) {
				// 	stdout.printf(@"[$(album.id)] $(album.artist) - $(album.album)\n");
				// }
				db.insert_new_albums(fetched_albums);

				var all_albums = db.get_albums();
				albums_list_model.set_albums(all_albums);
			});
		bandcamp.fetch_wishlist_async.begin(
			"1057301", (obj, res) => {
				var fetched_albums = bandcamp.fetch_collection_async.end(res);
				// foreach (Album? album in albums) {
				// 	stdout.printf(@"[$(album.id)] $(album.artist) - $(album.album)\n");
				// }
				db.insert_new_albums(fetched_albums);
				
				var all_albums = db.get_albums();
				albums_list_model.set_albums(all_albums);
			});
	}

	void filterby_cb(SimpleAction action, Variant? parameter) {
		var filter = build_filter(parameter.get_string(null));
		this.filtered_model.set_filter(filter);

		this.settings.set_enum("filter-by", filterby_to_enum(parameter.get_string(null)));
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

	private int filterby_to_enum(string s) {
		if (s == "all") {
			return 0;
		} else if (s == "wishlist") {
			return 1;
		} else if (s == "purchased") {
			return 2;
		}
		return 0;
	}

	private string enum_to_filterby(int e) {
		switch (e) {
		case 0:
			return "all";
		case 1:
			return "wishlist";
		case 2:
			return "purchased";
		default:
			return "all";
		}
	}

	private string enum_to_sortby(int e) {
		switch (e) {
		case 0:
			return "title_asc";
		case 1:
			return "title_desc";
		case 2:
			return "rating_asc";
		case 3:
			return "rating_desc";
		case 4:
			return "created_asc";
		case 5:
			return "created_desc";
		case 6:
			return "updated_asc";
		case 7:
			return "updated_desc";
		}
		return "title_asc";
	}

	private Settings? get_settings_from_system() {
		var sss = SettingsSchemaSource.get_default ();
		if (sss == null) {
			stdout.printf("Error loading settings schema\n");
			return null;
		}
		stdout.printf(Config.APP_ID + "\n");
		var schema = sss.lookup(Config.APP_ID, true);
		if (schema == null) {
			stdout.printf("Schema is null\n");
			return null;
		}
		return new Settings.full(schema, null, null);
	}

	private Settings? get_settings_from(string directory) {
		stdout.printf("get_settings_from %s\n", directory);
		try {
			var sss = new SettingsSchemaSource.from_directory (directory, null, false);
			var schema = sss.lookup (Config.APP_ID, false);
			if (schema == null) {
				stdout.printf ("The schema specified was not found on the custom location");
				return null;
			}

			return new Settings.full (schema, null, null);
		} catch (Error e) {
			stdout.printf ("An error ocurred: directory not found, corrupted files found, empty files...");
			return null;
		}
	}
}