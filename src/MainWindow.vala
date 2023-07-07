/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

public class CampCounselor.MainWindow : Gtk.ApplicationWindow {
	/* Create the window actions. */
	const ActionEntry[] actions = {
		/*{ "action name", cb to connect to "activate" signal, parameter type,
		  initial state, cb to connect to "change-state" signal } */
		{ "filterby", filterby_cb, "s", "'all'" },
		{ "sortby", sortby_cb, "s", "'artist_asc'" }
	};

	private AlbumListModel albums_list_model = null;
	private Gtk.FilterListModel filtered_model = null;
	private Gtk.SortListModel sorted_model = null;
	private AlbumSorter sorter = null;
	
	public MainWindow (CampCounselor.Application application) {
		Object (
			title: "Camp Counselor",
			application: application,
			resizable: true
			);
	}

	construct {
		set_default_size(600, 800);
		
		var db = new Database();
		var builder = new Gtk.Builder.from_resource("/net/line72/campcounselor/ui/headerbar.ui");
		var headerbar = (Gtk.HeaderBar)builder.get_object("headerbar");

		set_titlebar(headerbar);
		add_action_entries(actions, this);

		this.albums_list_model = new AlbumListModel();

		this.filtered_model = new Gtk.FilterListModel(albums_list_model, new Gtk.EveryFilter());

		this.sorter = new AlbumSorter(AlbumSorter.AlbumSortType.TITLE_ASC);
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

					li.album_band.label = a.artist;
					li.album_title.label = a.album;
					li.album_uri.uri = a.url;
					li.edit_comment_handler_id = li.edit_comment.clicked.connect(() => {
							stdout.printf(@"Clicked on $(a.artist)\n");
							var d = new AlbumEditComment(a, main_window);

							d.response.connect((response) => {
									if (response == Gtk.ResponseType.OK) {
										a.comment = d.comment.buffer.text;
										stdout.printf(a.comment + "\n");
										// save
										try {
											db.update_album(a);
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
		if (parameter.get_string(null) == "purchased") {
			var exp1 = new Gtk.PropertyExpression(typeof (Album), null, "purchased");
			var purchased_filter = new Gtk.BoolFilter(exp1);

			stdout.printf("switching to purchased only\n");
			this.filtered_model.set_filter(purchased_filter);
		} else if (parameter.get_string(null) == "wishlist") {
			var exp1 = new Gtk.PropertyExpression(typeof (Album), null, "purchased");
			var wishlist_filter = new Gtk.BoolFilter(exp1);
			wishlist_filter.set_invert(true);

			stdout.printf("switching to wishlist only\n");
			this.filtered_model.set_filter(wishlist_filter);
		} else {
			this.filtered_model.set_filter(new Gtk.EveryFilter());
		}
		
		action.set_state(parameter);
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
		
		action.set_state(parameter);
	}
}