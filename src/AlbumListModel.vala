/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	public class AlbumListModel : GLib.Object, GLib.ListModel {
		private Database _database = null;
		private uint _current_size = 0;

		public AlbumListModel(Database database) {
			this._database = database;
		}

		public void reset_albums() {
			var s = this._database.get_album_count();
			// send out a notification that our data has changed
			items_changed(0, this._current_size, s);
			this._current_size = s;
		}

		public uint get_n_items() {
			return this._current_size;
		}

		public GLib.Type get_item_type() {
			return typeof (Album);
		}

		public GLib.Object? get_item(uint position) {
			if (position > this._current_size) {
				return null;
			}

			//return _albums[(int) position];
			return null;
		}
	}
}