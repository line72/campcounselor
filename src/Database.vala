/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	public class Database : GLib.Object {
		private static int SCHEMA = 2;
		private Gda.Connection connection;
		
		public Database() {
		}

		public async void open() throws GLib.Error {
			try {
				this.connection = yield open_connection();
			} catch (GLib.Error e) {
				stdout.printf("Can't connect to database\n");
				throw e;
			}

			try {
				// look up the schema
				var r = this.connection.execute_select_command("SELECT * FROM schema_migrations ORDER BY id DESC LIMIT 1");
				var current_schema = r.get_value_at(r.get_column_index("schema"), 0);
				stdout.printf("schema=%d\n", get_value_as_int(current_schema));
				if (current_schema.get_int() != Database.SCHEMA) {
					this.connection.begin_transaction("migratedb", Gda.TransactionIsolation.SERVER_DEFAULT);
					migrate(get_value_as_int(current_schema));
					this.connection.commit_transaction("migratedb");
				}
			} catch (GLib.Error e) {
				stdout.printf("Database doesn't exist yet...: %s\n", e.message);
				this.connection.begin_transaction("createdb", Gda.TransactionIsolation.SERVER_DEFAULT);
				create_database();
				this.connection.commit_transaction("createdb");
			}
		}

		public uint get_album_count() {
			stdout.printf("get_album_count\n");
			var sql = new Gda.SqlBuilder(Gda.SqlStatementType.SELECT);
			sql.select_add_target("albums", null);
			sql.add_field_value_id(sql.add_id("id"), 0);

			try {
				var r = this.connection.statement_execute_select(sql.get_statement(), null);
				return r.get_n_rows();
			} catch (GLib.Error e) {
				stdout.printf("got an error: %s\n", e.message);
				return 0;
			}
		}

		public Gda.DataModelIter get_iter() throws GLib.Error {
			var sql = select_album();

			var r = this.connection.statement_execute_select(sql.get_statement(), null);
			return r.create_iter();
		}
		
		public Gee.ArrayList<Album> get_albums() {
			var albums = new Gee.ArrayList<Album>();
			
			var sql = select_album();

			try {
				var r = this.connection.statement_execute_select(sql.get_statement(), null);
				var result_iter = r.create_iter();
				while (result_iter.move_next()) {
					Album? a = to_album(result_iter);
					if (a != null) {
						albums.add(a);
					} else {
						stdout.printf("album is null?\n");
					}
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
				  get_value_as_int(
					r.get_value_at(
						r.get_column_index("last_refresh"), 0
				   )));
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
				int id = get_value_as_int(r.get_value_at(r.get_column_index("id"), 0));
				

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
			create_table_albums();
			create_table_schema_migrations();
			
			// migrate
			migrate(1);
		}
		
		public Album? to_album(Gda.DataModelIter iter) {
			if (iter.is_valid()) {
				var album = new Album(
									  get_field_as_int(iter, "id"),
									  get_field_as_string(iter, "bandcamp_id"),
									  get_field_as_string(iter, "bandcamp_band_id"),
									  get_field_as_string(iter, "album"),
									  get_field_as_string(iter, "artist"),
									  get_field_as_string(iter, "url"),
									  get_field_as_string(iter, "thumbnail_url"),
									  get_field_as_string(iter, "artwork_url"),
									  get_field_as_boolean(iter, "purchased"),
									  get_field_as_string(iter, "comment"),
									  get_field_as_int(iter, "rating")
									  );
				album.created_at = new DateTime.from_unix_utc(get_field_as_int(iter, "created_at"));
				album.updated_at = new DateTime.from_unix_utc(get_field_as_int(iter, "updated_at"));
				return album;
			} else {
				stdout.printf("iter isn't valid\n");
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

		private void create_table_albums() throws GLib.Error {
			// !mwd - See the following for all the possible 2nd values of
			//  a create table operation
			// https://gitlab.gnome.org/GNOME/libgda/-/blob/master/providers/postgres/postgres_specs_create_table.xml.in

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
			op.set_value_at("FALSE", @"/FIELDS_A/@COLUMN_DEFAULT/$(i)");
			// rating
			i++;
			op.set_value_at("rating", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("integer", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at("-1", @"/FIELDS_A/@COLUMN_DEFAULT/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_NNUL/$(i)");
			// comment
			i++;
			op.set_value_at("comment", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("text", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at("", @"/FIELDS_A/@COLUMN_DEFAULT/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_NNUL/$(i)");
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

			if (!this.connection.perform_operation(op)) {
				stdout.printf("Error creating albums table\n");
				throw new GLib.Error(823423, 0, "Error creating albums table");
			}

			// Create an Index
			
			// !mwd - See the following for all the possible index values
			// https://gitlab.gnome.org/GNOME/libgda/-/blob/master/providers/postgres/postgres_specs_create_index.xml.in
			
			op = this.connection.create_operation(Gda.ServerOperationType.CREATE_INDEX, null);
			op.set_value_at("bandcamp_id_idx", "/INDEX_DEF_P/INDEX_NAME");
			op.set_value_at("albums", "/INDEX_DEF_P/INDEX_ON_TABLE");
			op.set_value_at("UNIQUE", "/INDEX_DEF_P/INDEX_TYPE");
			op.set_value_at("bandcamp_id", "/INDEX_FIELDS_S/0/INDEX_FIELD");

			if (!this.connection.perform_operation(op)) {
				stdout.printf("Error creating bandcamp_id_idx index\n");
				throw new GLib.Error(823423, 0, "Error creating bandcamp_id_idx");
			}
		}

		private void create_table_schema_migrations() throws GLib.Error {
			var op = this.connection.create_operation(Gda.ServerOperationType.CREATE_TABLE, null);
			op.set_value_at("schema_migrations", "/TABLE_DEF_P/TABLE_NAME");
			// first column id primary key, autoincrement
			int i = 0;
			op.set_value_at("id", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("integer", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_AUTOINC/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_PKEY/$(i)");
			// schema
			i++;
			op.set_value_at("schema", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("integer", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at(@"$(Database.SCHEMA)", @"/FIELDS_A/@COLUMN_DEFAULT/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_NNUL/$(i)");

			if (!this.connection.perform_operation(op)) {
				stdout.printf("Error creating schema_migrations table\n");
				throw new GLib.Error(823423, 0, "Error creating schema_migrations table");
			}

			// insert the default value
			var col_names = new GLib.SList<string> ();
			col_names.append("schema");

			var values = new GLib.SList<GLib.Value?> ();
			values.append(Database.SCHEMA);
			
			this.connection.insert_row_into_table_v("schema_migrations", col_names, values);
		}

		private void create_table_config() throws GLib.Error {
			var op = this.connection.create_operation(Gda.ServerOperationType.CREATE_TABLE, null);
			op.set_value_at("config", "/TABLE_DEF_P/TABLE_NAME");
			// first column id primary key, autoincrement
			int i = 0;
			op.set_value_at("id", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("integer", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_AUTOINC/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_PKEY/$(i)");
			// schema
			i++;
			op.set_value_at("last_refresh", @"/FIELDS_A/@COLUMN_NAME/$(i)");
			op.set_value_at("integer", @"/FIELDS_A/@COLUMN_TYPE/$(i)");
			op.set_value_at("0", @"/FIELDS_A/@COLUMN_DEFAULT/$(i)");
			op.set_value_at("TRUE", @"/FIELDS_A/@COLUMN_NNUL/$(i)");

			if (!this.connection.perform_operation(op)) {
				stdout.printf("Error creating config table\n");
				throw new GLib.Error(823423, 0, "Error creating config table");
			}
		}
		
		private void migrate(int current_schema) {
			try {
				var r = this.connection.execute_select_command("SELECT * FROM schema_migrations ORDER BY id DESC LIMIT 1");
				int schema_id = get_value_as_int(r.get_value_at(r.get_column_index("id"), 0));

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
			this.create_table_config();

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

		private string get_field_as_string(Gda.DataModelIter iter, string field, string fallback = "") {
			if (iter.is_valid()) {
				Value? f = iter.get_value_for_field(field);
				if (f != null && f.holds(GLib.Type.STRING)) {
					return f.get_string();
				} else if (f != null && f.type().name() == "GdaText") {
					Gda.Text o = (Gda.Text)f.get_boxed();
					return o.get_string();
				} else {
					stdout.printf("Error: Invalid string type\n");
				}
			}
			return fallback;
		}

		private int get_field_as_int(Gda.DataModelIter iter, string field, int fallback = 0) {
			if (iter.is_valid()) {
				Value? f = iter.get_value_for_field(field);
				if (f != null) {
					return get_value_as_int(f, fallback);
				}
			}
			return fallback;
		}
		private bool get_field_as_boolean(Gda.DataModelIter iter, string field, bool fallback = false) {
			if (iter.is_valid()) {
				Value? f = iter.get_value_for_field(field);
				if (f != null && f.holds(GLib.Type.BOOLEAN)) {
					return f.get_boolean();
				} else {
					stdout.printf("Error: invalid boolean type\n");
				}
			}
			return fallback;
		}

		private int get_value_as_int(Value v, int fallback = 0) {
			if (v.holds(GLib.Type.INT)) {
				return v.get_int();
			} else if (v.holds(GLib.Type.INT64)) {
				return (int)v.get_int64();
			}
			return fallback;
		}

		private async Gda.Connection open_connection() throws GLib.Error {
			var mgr = SettingsManager.get_instance();
			if (mgr.settings.get_enum("database-backend") == 0) {
				stdout.printf("Using SQLite Backend\n");
				// sqlite
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

				return Gda.Connection.open_from_string("SQLite",
													   @"DB_DIR=$(db_dir);DB_NAME=campcounselor-test",
													   null,
													   Gda.ConnectionOptions.NONE);
				
			} else {
				stdout.printf("Using PostgreSQL Backend\n");
				var host = mgr.db_settings.get_string("host");
				var db = mgr.db_settings.get_string("database");
				var port = mgr.db_settings.get_int("port");
				var username = mgr.db_settings.get_string("username");
				
				// get password from secrets manager
				var secret = new Secret.Schema (Config.APP_ID, Secret.SchemaFlags.NONE,
												"host", Secret.SchemaAttributeType.STRING,
												"database", Secret.SchemaAttributeType.STRING,
												"port", Secret.SchemaAttributeType.INTEGER,
												"username", Secret.SchemaAttributeType.STRING
												);
				
				var secret_attr = new GLib.HashTable<string, string>(str_hash, str_equal);
				secret_attr["host"] = host;
				secret_attr["database"] = db;
				secret_attr["port"] = port.to_string();
				secret_attr["username"] = username;

				var password = yield Secret.password_lookupv(secret, secret_attr, null);
				if (password == null || password == "") {
					stdout.printf("No DB password!\n");
					throw new GLib.Error(823423, 0, "Missing Password");
				}
				return Gda.Connection.open_from_string("PostgreSQL",
													   @"HOST=$(host);DB_NAME=$(db);PORT=$(port)",
													   @"USERNAME=$(username);PASSWORD=$(password)",
													   Gda.ConnectionOptions.NONE);
			}
		}
	}
}