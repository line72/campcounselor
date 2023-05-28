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

		var factory = new Gtk.SignalListItemFactory();
		factory.setup.connect(setup_listitem_cb);
		factory.bind.connect(bind_listitem_cb);

		var selection = new Gtk.NoSelection(albums_list_model);

		var grid_view = new Gtk.GridView(selection, factory);
		grid_view.set_hscroll_policy(Gtk.ScrollablePolicy.NATURAL);
		grid_view.set_vscroll_policy(Gtk.ScrollablePolicy.NATURAL);

		scrolled_window.set_child(grid_view);
		
		present ();

		var bandcamp = new BandCamp();

		bandcamp.fetch_collection_async.begin(
			"1057301", (obj, res) => {
				var albums = bandcamp.fetch_collection_async.end(res);
				foreach (Album? album in albums) {
					stdout.printf(@"[$(album.id)] $(album.artist) - $(album.album)\n");
				}
				albums_list_model.set_albums(albums);
			});
	}

	void setup_listitem_cb(Gtk.ListItemFactory factory, Gtk.ListItem list_item) {
		var builder = new Gtk.Builder();
		builder.add_from_file("data/ui/album.ui");
		var obj = builder.get_object("album") as Gtk.Box;

		list_item.set_child(obj);
	}

	void bind_listitem_cb(Gtk.ListItemFactory factory, Gtk.ListItem list_item) {
		var album = list_item.get_item() as Album;
		var widget = list_item.get_child() as Gtk.Box;
		var title = widget.get_last_child() as Gtk.Label;

		title.set_label(@"$(album.artist)\n$(album.album)");
	}
}