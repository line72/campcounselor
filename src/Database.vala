/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	class Database : GLib.Object {
		private Gda.Connection connection;
		
		public Database() {
			try {
				// !mwd - TODO, open from our var directory
				connection = Gda.Connection.open_from_string("SQLite",
															 "DB_DIR=.;DB_NAME=campcounselor",
															 null,
															 Gda.ConnectionOptions.NONE);

				// look up the schema
				var r = this.connection.execute_select_command("SELECT * FROM schema ORDER BY id DESC LIMIT 1");
			} catch (GLib.Error e) {
				stdout.printf("Database doesn't exist yet...: %s\n", e.message);
			}
		}

		public void create_database() {
			this.connection.execute_non_select_command("CREATE TABLE album (id int PRIMARY KEY, bandcamp_id string, bandcamp_band_id string, album string, artist string)");
		}
	}
}