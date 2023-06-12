/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	class Database : GLib.Object {
		private static int SCHEMA = 1;
		private Gda.Connection connection;
		
		public Database() throws GLib.Error {
			try {
				// !mwd - TODO, open from our var directory
				this.connection = Gda.Connection.open_from_string("SQLite",
																  "DB_DIR=.;DB_NAME=campcounselor",
																  null,
																  Gda.ConnectionOptions.NONE);

				// look up the schema
				var r = this.connection.execute_select_command("SELECT * FROM schema_migrations ORDER BY id DESC LIMIT 1");
			} catch (GLib.Error e) {
				stdout.printf("Database doesn't exist yet...: %s\n", e.message);
				create_database();
			}
		}

		public void create_database() throws GLib.Error {
			this.connection.execute_non_select_command(
				"CREATE TABLE album (id int PRIMARY KEY, bandcamp_id string, " +
				"bandcamp_band_id string, album string, artist string, " +
				"url string, thumbnail_url string, artwork_url string)"
				);
			this.connection.execute_non_select_command(
				@"CREATE TABLE schema_migrations (id int PRIMARY_KEY, schema int DEFAULT $(Database.SCHEMA))"
				);
			this.connection.insert_row_into_table_v("schema_migrations", SList<string>() { "schema" }, SList<int>() { Database.SCHEMA });
		}
	}
}