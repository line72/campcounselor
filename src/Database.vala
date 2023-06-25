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
				var current_schema = r.get_value_at(r.get_column_index("schema"), 0);
				stdout.printf("schema=%d\n", current_schema.get_int());
				if (current_schema.get_int() != Database.SCHEMA) {
					stdout.printf("Do a migratino1!!\n");
				}
			} catch (GLib.Error e) {
				stdout.printf("Database doesn't exist yet...: %s\n", e.message);
				create_database();
			}
		}

		public Gee.ArrayList<Album> get_albums() {
			var albums = new Gee.ArrayList<Album>();
			
			var sql = select_album();

			var r = this.connection.statement_execute_select(sql.get_statement(), null);
			var result_iter = r.create_iter();
			while (result_iter.move_next()) {
				Album a = to_album(result_iter);
				albums.add(a);
			}

			return albums;
		}
		
		public Album? get_by_bandcamp_id(string bandcamp_id) {
			var sql = select_album();
			
			var bandcamp_id_field = sql.add_id("bandcamp_id");
			var bandcamp_id_param = sql.add_expr_value(bandcamp_id);
			var bandcamp_id_cond = sql.add_cond(Gda.SqlOperatorType.EQ, bandcamp_id_field, bandcamp_id_param, 0);

			sql.set_where(bandcamp_id_cond);

			//stdout.printf("querying %s\n", sql.get_statement().serialize());
			var r = this.connection.statement_execute_select(sql.get_statement(), null);

			var result_iter = r.create_iter();
			while (result_iter.move_next()) {
				// stdout.printf("checking result of %s\n", bandcamp_id);
				Album? a = to_album(result_iter);
				if (a != null) {
					return a;
				}
			}
			stdout.printf("no results found for %s\n", bandcamp_id);
			return null;
		}
		
		public void insert_new_albums(Gee.ArrayList<Album?> albums) {
			foreach (Album? album in albums) {
				Album? db_album = get_by_bandcamp_id(album.bandcamp_id);
				if (db_album == null) {
					// insert this
					stdout.printf("Inserting album %s\n", album.bandcamp_id);
					try {
						insert_album(album);
					} catch (GLib.Error e) {
						stdout.printf("ERROR: Unable to insert album %s: %s\n", album.bandcamp_id, e.message);
					}
				}
			}
		}

		public void insert_album(Album album) throws GLib.Error {
			var col_names = new GLib.SList<string>();
			var values = new GLib.SList<GLib.Value?>();

			col_names.append("id");
			col_names.append("bandcamp_id");
			col_names.append("bandcamp_band_id");
			col_names.append("album");
			col_names.append("artist");
			col_names.append("url");
			col_names.append("thumbnail_url");
			col_names.append("artwork_url");
			col_names.append("rating");
			col_names.append("comment");
			col_names.append("purchased");

			values.append(null);
			values.append(album.id);
			values.append(album.band_id);
			values.append(album.album);
			values.append(album.artist);
			values.append(album.url);
			values.append(album.thumbnail_url);
			values.append(album.artwork_url);
			values.append(album.rating);
			values.append(album.comment);
			values.append(album.purchased);

			this.connection.insert_row_into_table_v("albums",
													col_names,
													values);
			
		}

		public void update_album(Album album) throws GLib.Error {
			var col_names = new GLib.SList<string>();
			var values = new GLib.SList<GLib.Value?>();

			col_names.append("bandcamp_id");
			col_names.append("bandcamp_band_id");
			col_names.append("album");
			col_names.append("artist");
			col_names.append("url");
			col_names.append("thumbnail_url");
			col_names.append("artwork_url");
			col_names.append("rating");
			col_names.append("comment");
			col_names.append("purchased");

			values.append(album.bandcamp_id);
			values.append(album.band_id);
			values.append(album.album);
			values.append(album.artist);
			values.append(album.url);
			values.append(album.thumbnail_url);
			values.append(album.artwork_url);
			values.append(album.rating);
			values.append(album.comment);
			values.append(album.purchased);

			stdout.printf("Updating album %d\n", album.id);
			this.connection.update_row_in_table_v("albums",
												  "id",
												  album.id,
												  col_names,
												  values);
		}
		
		private void create_database() throws GLib.Error {
			this.connection.execute_non_select_command(
				"CREATE TABLE albums (id integer PRIMARY KEY AUTOINCREMENT, " +
				"bandcamp_id string, " +
				"bandcamp_band_id string, album string, artist string, " +
				"url string, thumbnail_url string, artwork_url string, " +
				"purchased boolean, " +
				"rating integer, comment text)"
				);
			this.connection.execute_non_select_command(
				"CREATE UNIQUE INDEX bandcamp_id_idx " +
				"ON albums (bandcamp_id)"
				);
			this.connection.execute_non_select_command(
				"CREATE TABLE schema_migrations (id integer PRIMARY KEY AUTOINCREMENT, " +
				@"schema int DEFAULT $(Database.SCHEMA))"
				);

			var col_names = new GLib.SList<string> ();
			col_names.append("id");
			col_names.append("schema");

			var values = new GLib.SList<GLib.Value?> ();
			values.append(null);
			values.append(Database.SCHEMA);
			
			this.connection.insert_row_into_table_v("schema_migrations", col_names, values);
		}
		
		private Album? to_album(Gda.DataModelIter iter) {
			if (iter.is_valid()) {
				var album = new Album(
									  iter.get_value_for_field("id").get_int(),
									  iter.get_value_for_field("bandcamp_id").get_string(),
									  iter.get_value_for_field("bandcamp_band_id").get_string(),
									  iter.get_value_for_field("album").get_string(),
									  iter.get_value_for_field("artist").get_string(),
									  iter.get_value_for_field("url").get_string(),
									  iter.get_value_for_field("thumbnail_url").get_string(),
									  iter.get_value_for_field("artwork_url").get_string(),
									  iter.get_value_for_field("purchased").get_boolean(),
									  iter.get_value_for_field("comment").get_string(),
									  iter.get_value_for_field("rating").get_int()
									  );
				return album;
			}
			return null;
		}

		private Gda.SqlBuilder select_album() {
			var sql = new Gda.SqlBuilder(Gda.SqlStatementType.SELECT);
			sql.select_add_target("albums", null);
			sql.add_field_value_id(sql.add_id("id"), 0);
			sql.add_field_value_id(sql.add_id("bandcamp_id"), 0);
			sql.add_field_value_id(sql.add_id("bandcamp_band_id"), 0);
			sql.add_field_value_id(sql.add_id("album"), 0);
			sql.add_field_value_id(sql.add_id("artist"), 0);
			sql.add_field_value_id(sql.add_id("url"), 0);
			sql.add_field_value_id(sql.add_id("thumbnail_url"), 0);
			sql.add_field_value_id(sql.add_id("artwork_url"), 0);
			sql.add_field_value_id(sql.add_id("rating"), 0);
			sql.add_field_value_id(sql.add_id("comment"), 0);
			sql.add_field_value_id(sql.add_id("purchased"), 0);

			return sql;
		}

	}
}