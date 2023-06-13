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
		var builder = new Gtk.Builder();
		builder.add_from_file("data/ui/headerbar.ui");
		var headerbar = (Gtk.HeaderBar)builder.get_object("headerbar");

		set_titlebar(headerbar);

		var albums_list_model = new AlbumListModel();
		
		var scrolled_window = new Gtk.ScrolledWindow();
		set_child(scrolled_window);

		try {
			var factory = new Gtk.BuilderListItemFactory.from_resource(null, "/net/line72/campcounselor/ui/album.ui");

			var selection = new Gtk.NoSelection(albums_list_model);

			var grid_view = new Gtk.GridView(selection, factory);
			grid_view.set_hscroll_policy(Gtk.ScrollablePolicy.NATURAL);
			grid_view.set_vscroll_policy(Gtk.ScrollablePolicy.NATURAL);
			
			scrolled_window.set_child(grid_view);
		} catch (GLib.Error e) {
			stdout.printf("!!ERROR: %s\n", e.message);
		}
		
		present ();

		// temp
		var db = new Database();
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
}