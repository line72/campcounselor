/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

public class CampCounselor.AlbumListModel : GLib.Object, GLib.ListModel {
	private Gee.ArrayList<Album> _albums = new Gee.ArrayList<Album>();

	public AlbumListModel() {

	}

	public void set_albums(Gee.ArrayList<Album> albums) {
		var previous_size = this._albums.size;
		
		this._albums = albums;

		// send out a notification that our data has changed
		items_changed(0, previous_size, this._albums.size);
	}

	public uint get_n_items() {
		return _albums.size;
	}

	public GLib.Type get_item_type() {
		return typeof (Album);
	}

	public GLib.Object? get_item(uint position) {
		if (position > _albums.size) {
			return null;
		}

		return _albums[(int) position];
	}
}