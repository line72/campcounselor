/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	public class AlbumListModel : GLib.Object, GLib.ListModel {
		private Database _database = null;
		private Gda.DataModelIter _iter = null;
		private uint _current_size = 0;

		public AlbumListModel() {
		}
		
		public void set_database(Database database) {
			this._database = database;
		}

		public void reset_albums() {
			if (this._database != null) {
				var prev_size = this._current_size;
				this._current_size = this._database.get_album_count();
				stdout.printf("size=%u\n", this._current_size);
				try {
					this._iter = this._database.get_iter();
				} catch (GLib.Error e) {
					stdout.printf("Error resetting albums\n");
					this._iter = null;
				}

				// send out a notification that our data has changed
				items_changed(0, prev_size, this._current_size);
			}
		}

		public uint get_n_items() {
			return this._current_size;
		}

		public GLib.Type get_item_type() {
			return typeof (Album);
		}

		public GLib.Object? get_item(uint position) {
			stdout.printf("get_item %u %u\n", position, this._current_size);
			if (position > this._current_size || this._iter == null) {
				stdout.printf("uh-oh\n");
				return null;
			}

			var b = this._iter.move_to_row((int)position);
			stdout.printf("moved to %d %d\n", (int)position, (int)b);
			return this._database.to_album(this._iter);
		}
	}
}