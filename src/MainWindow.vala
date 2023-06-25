/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

public class CampCounselor.MainWindow : Gtk.Window {
	public MainWindow (CampCounselor.Application application) {
		Object (
			title: "Camp Counselor",
			application: application,
			resizable: true
			);
	}

	construct {
		var db = new Database();
		var builder = new Gtk.Builder.from_resource("/net/line72/campcounselor/ui/headerbar.ui");
		var headerbar = (Gtk.HeaderBar)builder.get_object("headerbar");

		set_titlebar(headerbar);

		var albums_list_model = new AlbumListModel();
		
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
			
			var selection = new Gtk.NoSelection(albums_list_model);

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

	void onButtonClicked(Gtk.Button btn) {
		stdout.printf("onButtonClicked");
	}
}