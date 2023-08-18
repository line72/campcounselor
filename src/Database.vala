/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	class Database : GLib.Object {
		private static int SCHEMA = 2;
		private Gda.Connection connection;
		
		public Database() throws GLib.Error {
			try {
				var db_f = File.new_build_filename(
					Environment.get_user_state_dir(),
					Config.APP_ID
					);
				var db_dir = db_f.get_path();
				try {
					db_f.make_directory_with_parents();
				} catch (GLib.Error e) {
					// pass
				}
				this.connection = Gda.Connection.open_from_string("PostgreSQL",
																  @"HOST=10.105.105.29;DB_NAME=campcounselor",
																  @"USERNAME=campcounselor;PASSWORD=mysecretpassword",
																  Gda.ConnectionOptions.NONE);

				// look up the schema
				var r = this.connection.execute_select_command("SELECT * FROM schema_migrations ORDER BY id DESC LIMIT 1");
				var current_schema = r.get_value_at(r.get_column_index("schema"), 0);
				stdout.printf("schema=%d\n", current_schema.get_int());
				if (current_schema.get_int() != Database.SCHEMA) {
					migrate(current_schema.get_int());
				}
			} catch (GLib.Error e) {
				stdout.printf("Database doesn't exist yet...: %s\n", e.message);
				try {
					create_database();
				} catch (GLib.Error e) {
					stdout.printf("Error creating database: %s\n", e.message);
				}
			}
		}

		public Gee.ArrayList<Album> get_albums() {
			var albums = new Gee.ArrayList<Album>();
			
			var sql = select_album();

			try {
				var r = this.connection.statement_execute_select(sql.get_statement(), null);
				var result_iter = r.create_iter();
				while (result_iter.move_next()) {
					Album a = to_album(result_iter);
					albums.add(a);
				}
				
				return albums;
			} catch (GLib.Error e) {
				stdout.printf("Error: Database.get_albums: %s\n", e.message);
				return new Gee.ArrayList<Album>();
			}
		}
		
		public Album? get_by_bandcamp_id(string bandcamp_id) {
			var sql = select_album();
			
			var bandcamp_id_field = sql.add_id("bandcamp_id");
			var bandcamp_id_param = sql.add_expr_value(bandcamp_id);
			var bandcamp_id_cond = sql.add_cond(Gda.SqlOperatorType.EQ, bandcamp_id_field, bandcamp_id_param, 0);

			sql.set_where(bandcamp_id_cond);

			try {
				var r = this.connection.statement_execute_select(sql.get_statement(), null);

				var result_iter = r.create_iter();
				while (result_iter.move_next()) {
					// stdout.printf("checking result of %s\n", bandcamp_id);
					Album? a = to_album(result_iter);
					if (a != null) {
						return a;
					}
				}

				return null;
			} catch (GLib.Error e) {
				stdout.printf("Error: Database.get_by_bandcamp_id: %s\n", e.message);
				return null;
			}
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

			var now = new DateTime.now_utc();
			
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
			col_names.append("created_at");
			col_names.append("updated_at");

			var created_at = album.created_at ?? now;
			var updated_at = album.updated_at ?? now;
			
			values.append(null);
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
			values.append(created_at.to_unix());
			values.append(updated_at.to_unix());

			this.connection.insert_row_into_table_v("albums",
													col_names,
													values);
			
		}

		public void update_album(Album album) throws GLib.Error {
			var col_names = new GLib.SList<string>();
			var values = new GLib.SList<GLib.Value?>();

			var now = new DateTime.now_utc();

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
			col_names.append("updated_at");

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
			values.append(now.to_unix());

			stdout.printf("Updating album %d\n", album.id);
			this.connection.update_row_in_table_v("albums",
												  "id",
												  album.id,
												  col_names,
												  values);
		}

		public DateTime last_refresh() {
			try {
				var r = this.connection.execute_select_command("SELECT * from config ORDER BY id DESC limit 1");
				return new DateTime.from_unix_utc(
					r.get_value_at(
						r.get_column_index("last_refresh"), 0
						).get_int());
			} catch (GLib.Error e) {
				stdout.printf("Error fetching last refresh: %s\n", e.message);
				return new DateTime.from_unix_utc(0);
			}
		}

		public void update_last_refresh(DateTime d) {
			var col_names = new GLib.SList<string> ();
			col_names.append("last_refresh");

			var values = new GLib.SList<GLib.Value?> ();
			values.append(d.to_unix());
			
			try {
				var r = this.connection.execute_select_command("SELECT * FROM config ORDER BY id DESC LIMIT 1");
				int id = r.get_value_at(r.get_column_index("id"), 0).get_int();
				

				this.connection.update_row_in_table_v("config",
													  "id",
													  id,
													  col_names,
													  values);
			} catch (GLib.Error e) {
				// no config yet, insert a new row
				try {
					this.connection.insert_row_into_table_v("config",
															col_names,
															values);
				} catch (GLib.Error e) {
					stdout.printf("Error updating last refresh: %sn", e.message);
				}
			}
		}
		
		private void create_database() throws GLib.Error {
			stdout.printf("CREATING NEW DATABASE!!!\n");
			// this.connection.execute_non_select_command(
			// 	"CREATE TABLE albums (id integer PRIMARY KEY AUTOINCREMENT, " +
			// 	"bandcamp_id string, " +
			// 	"bandcamp_band_id string, album string, artist string, " +
			// 	"url string, thumbnail_url string, artwork_url string, " +
			// 	"purchased boolean, " +
			// 	"rating integer, comment text, " +
			// 	"created_at integer, updated_at integer)"
			// 	);

			// create the albums table
			var op = this.connection.create_operation(Gda.ServerOperationType.CREATE_TABLE, null);
			op.set_value_at("albums", "/TABLE_DEF_P/TABLE_NAME");
			// first column id primary key, autoincrement
			int i = 0;
			op.set_value_at("id", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("integer", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_AUTOINC/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_PKEY/$(i)");
			// bandcamp_id
			i++;
			op.set_value_at("bandcamp_id", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("varchar", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at("50", @"/FIELDS_A/@COLUMN_SIZE/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_NNUL/$(i)");
			// bandcamp_band_id
			i++;
			op.set_value_at("bandcamp_band_id", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("varchar", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at("50", @"/FIELDS_A/@COLUMN_SIZE/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_NNUL/$(i)");
			// album
			i++;
			op.set_value_at("album", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("varchar", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at("4096", @"/FIELDS_A/@COLUMN_SIZE/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_NNUL/$(i)");
			// artist
			i++;
			op.set_value_at("artist", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("varchar", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at("4096", @"/FIELDS_A/@COLUMN_SIZE/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_NNUL/$(i)");
			// url
			i++;
			op.set_value_at("url", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("varchar", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at("4096", @"/FIELDS_A/@COLUMN_SIZE/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_NNUL/$(i)");
			// thumbnail_url
			i++;
			op.set_value_at("thumbnail_url", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("varchar", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at("4096", @"/FIELDS_A/@COLUMN_SIZE/$(i)");
			// artwork_url
			i++;
			op.set_value_at("artwork_url", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("varchar", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at("4096", @"/FIELDS_A/@COLUMN_SIZE/$(i)");
			// purchased
			i++;
			op.set_value_at("purchased", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("boolean", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at("FALSE", @"/FIELDS_A/@COLUMN_DEFUALT/$(i)");
			// rating
			i++;
			op.set_value_at("rating", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("integer", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at("-1", @"/FIELDS_A/@COLUMN_DEFUALT/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_NNUL/$(i)");
			// comment
			i++;
			op.set_value_at("comment", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("text", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			// created_at
			i++;
			op.set_value_at("created_at", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("integer", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_NNUL/$(i)");
			// updated_at
			i++;
			op.set_value_at("updated_at", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("integer", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_NNUL/$(i)");

			var r = this.connection.perform_operation(op);
			if (!r) {
				stdout.printf("Uanble to perform operation\n");
			}
			stdout.printf("SUCCESSSSSS\n");
				

	// provider = gda_connection_get_provider (cnc);
	// op = gda_server_provider_create_operation (provider, cnc, GDA_SERVER_OPERATION_CREATE_TABLE, NULL, &error);
	// if (!op) {
	// 	g_print ("CREATE TABLE operation is not supported by the provider: %s\n",
	// 		 error && error->message ? error->message : "No detail");
	// 	exit (1);
	// }

	// /* Set parameter's values */
	// /* table name */
	// if (!gda_server_operation_set_value_at (op, "products", &error, "/TABLE_DEF_P/TABLE_NAME")) goto on_set_error;
	// if (!gda_server_operation_set_value_at (op, "InnoDB", &error, "/TABLE_OPTIONS_P/TABLE_ENGINE")) goto on_set_error;

	// /* "id' field */
	// i = 0;
	// if (!gda_server_operation_set_value_at (op, "id", &error, "/FIELDS_A/@COLUMN_NAME/%d", i)) goto on_set_error;
	// if (!gda_server_operation_set_value_at (op, "integer", &error, "/FIELDS_A/@COLUMN_TYPE/%d", i)) goto on_set_error;
	// if (!gda_server_operation_set_value_at (op, "TRUE", &error, "/FIELDS_A/@COLUMN_AUTOINC/%d", i)) goto on_set_error;
	// if (!gda_server_operation_set_value_at (op, "TRUE", &error, "/FIELDS_A/@COLUMN_PKEY/%d", i)) goto on_set_error;
	
	// /* 'product_name' field */
	// i++;
	// if (!gda_server_operation_set_value_at (op, "product_name", &error, "/FIELDS_A/@COLUMN_NAME/%d", i)) goto on_set_error;
	// if (!gda_server_operation_set_value_at (op, "varchar", &error, "/FIELDS_A/@COLUMN_TYPE/%d", i)) goto on_set_error;
	// if (!gda_server_operation_set_value_at (op, "50", &error, "/FIELDS_A/@COLUMN_SIZE/%d", i)) goto on_set_error;
	// if (!gda_server_operation_set_value_at (op, "TRUE", &error, "/FIELDS_A/@COLUMN_NNUL/%d", i)) goto on_set_error;


	// /* Actually execute the operation */
	// if (! gda_server_provider_perform_operation (provider, cnc, op, &error)) {
	// 	g_print ("Error executing the operation: %s\n",
	// 		 error && error->message ? error->message : "No detail");
	// 	exit (1);
	// }
	// g_object_unref (op);


			
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

			// migrate
			migrate(1);
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
				album.created_at = new DateTime.from_unix_utc(iter.get_value_for_field("created_at").get_int());
				album.updated_at = new DateTime.from_unix_utc(iter.get_value_for_field("updated_at").get_int());
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
			sql.add_field_value_id(sql.add_id("created_at"), 0);
			sql.add_field_value_id(sql.add_id("updated_at"), 0);

			return sql;
		}

		private void migrate(int current_schema) {
			try {
				var r = this.connection.execute_select_command("SELECT * FROM schema_migrations ORDER BY id DESC LIMIT 1");
				int schema_id = r.get_value_at(r.get_column_index("id"), 0).get_int();

				// switch statements can't fall through...
				if (current_schema == 1) {
					migrate_1_to_2(schema_id);
				}
			} catch (GLib.Error e) {
				stdout.printf("Error migrating from %d to %d: %s\n", current_schema, Database.SCHEMA, e.message);
			}
		}

		private void migrate_1_to_2(int id) throws GLib.Error {
			stdout.printf("migrating database: 1->2\n");
			this.connection.execute_non_select_command(
				"CREATE TABLE config (id integer PRIMARY KEY AUTOINCREMENT, " +
				"last_refresh integer DEFAULT 0)"
				);

			// set schema to 2
			var col_names = new GLib.SList<string> ();
			col_names.append("schema");

			var values = new GLib.SList<GLib.Value?> ();
			values.append(2);
			this.connection.update_row_in_table_v("schema_migrations",
												  "id",
												  id,
												  col_names,
												  values);
												  
		}
	}
}