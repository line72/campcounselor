/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	[GtkTemplate (ui = "/net/line72/campcounselor/ui/setupdialog.ui")]
	public class SetupDialog : Adw.Window {
		[GtkChild( name = "setup_navigation_view" )]
		public unowned Adw.NavigationView navigation;
		
		[GtkChild( name = "setup_toast" )]
		public unowned Adw.ToastOverlay toast;

		[GtkChild( name = "username_lbl" )]
		public unowned Adw.EntryRow username;

		[GtkChild( name = "username_btn" )]
		public unowned Gtk.Button username_btn;

		[GtkChild( name = "database_provider" )]
		public unowned Adw.ComboRow database;

		[GtkChild( name = "database_btn" )]
		public unowned Gtk.Button database_btn;

		[GtkChild( name = "postgresql_preferences" )]
		public unowned Adw.PreferencesGroup postgresql_prefs;

		[GtkChild( name = "postgresql_host" )]
		public unowned Adw.EntryRow postgresql_host;
		
		[GtkChild( name = "postgresql_dbname" )]
		public unowned Adw.EntryRow postgresql_dbname;
		
		[GtkChild( name = "postgresql_port" )]
		public unowned Adw.EntryRow postgresql_port;
		
		[GtkChild( name = "postgresql_username" )]
		public unowned Adw.EntryRow postgresql_username;
		
		[GtkChild( name = "postgresql_password" )]
		public unowned Adw.PasswordEntryRow postgresql_password;
		
		public SetupDialog(Gtk.Window? parent) {
			set_transient_for(parent);
			set_modal(true);

			var mgr = SettingsManager.get_instance();

			connect_username(mgr);
			connect_database(mgr);

			// this.close_request.connect(() => {
			// 		return true;
			// 	});
		}

		private void connect_username(SettingsManager mgr) {
			username.apply.connect(() => {
				});
			username_btn.clicked.connect(() => {
					username_insensitive();
					
					stdout.printf("Apply: %s\n", username.text);
					var bandcamp = new BandCamp(mgr.settings.get_string("bandcamp-url"));
					var uname = username.text;
					bandcamp.fetch_fan_id_from_username.begin(
						uname, (obj, res) => {
							var fan_id = bandcamp.fetch_fan_id_from_username.end(res);

							if (fan_id == null) {
								// show an error
								stdout.printf("Invalid fan id\n");

								var t = new Adw.Toast("Invalid bandcamp username");
								t.timeout = 5;
								toast.add_toast(t);
								
								username_sensitive();
							} else {
								stdout.printf("Fan Id=%s\n", fan_id);
								// save it to settings
								mgr.settings.set_string("bandcamp-fan-id", fan_id);
								// move to page 2
								navigation.push_by_tag("page-2");
							}
						});
				});

			this.set_default_widget(username_btn);
		}

		private void connect_database(SettingsManager mgr) {
			var db = mgr.settings.get_string("database-backend");
			if (db == "PostgreSQL") {
				database.set_selected(1);
			} else {
				database.set_selected(0);
			}
			database.notify["selected"].connect(() => {
					if (database.get_selected() == 0) {
						postgresql_prefs.visible = false;
					} else {
						postgresql_prefs.visible = true;
					}
				});

			database_btn.clicked.connect(() => {
					database_insensitive();

					stdout.printf("clicked\n");
					// try to open the database
					if (database.get_selected() == 0) {
						// save to the settingsg
						stdout.printf("setting prefs\n");
						mgr.settings.set_string("database-backend", "SQLite");
						stdout.printf("closing\n");
						this.close();
						stdout.printf("closed!\n");
					} else {
						// test the database
						var db1 = new Database();

						var db_host = postgresql_host.text;
						var db_name = postgresql_dbname.text;
						var db_port = int.parse(postgresql_port.text);
						var db_port_str = postgresql_port.text;
						var db_username = postgresql_username.text;
						var db_password = postgresql_password.text;
						
						db1.open_with.begin(db_host, db_name, db_port, db_username, db_password,
							(obj, res) => {
								try {
									db1.open_with.end(res);

									// save everything to settings
									mgr.settings.set_string("database-backend", "PostgreSQL");
									mgr.db_settings.set_string("host", db_host);
									mgr.db_settings.set_string("database", db_name);
									mgr.db_settings.set_int("port", db_port);
									mgr.db_settings.set_string("username", db_username);

									// get password from secrets manager
									var secret = new Secret.Schema (Config.APP_ID, Secret.SchemaFlags.NONE,
																	"host", Secret.SchemaAttributeType.STRING,
																	"database", Secret.SchemaAttributeType.STRING,
																	"port", Secret.SchemaAttributeType.INTEGER,
																	"username", Secret.SchemaAttributeType.STRING
										);
				
									var secret_attr = new GLib.HashTable<string, string>(str_hash, str_equal);
									secret_attr["host"] = db_host;
									secret_attr["database"] = db_name;
									secret_attr["port"] = db_port_str;
									secret_attr["username"] = db_username;

									Secret.password_storev_sync(secret, secret_attr, null, "Camp Counselor DB", db_password);
									
									// success
									this.close();
								} catch (GLib.Error e) {
									var t = new Adw.Toast(@"Unable to connect to database: $(e.message)");
									t.timeout = 5;
									toast.add_toast(t);

									database_sensitive();
								}
							});
					}
				});
			
			var host = mgr.db_settings.get_string("host");
			var dbname = mgr.db_settings.get_string("database");
			var port = mgr.db_settings.get_int("port");
			var username = mgr.db_settings.get_string("username");
			
			postgresql_host.text = host;
			postgresql_dbname.text = dbname;
			postgresql_port.text = @"$port";
			postgresql_username.text = username;
			
			if (db == "PostgreSQL") {
				postgresql_prefs.visible = true;
			} else {
				postgresql_prefs.visible = false;
			}
		}

		private void username_insensitive() {
			// make the button insensitive
			username.sensitive = false;
			username_btn.sensitive = false;
			username_btn.icon_name = "process-stop-symbolic";
		}

		private void username_sensitive() {
			// make the button sensitive
			username.sensitive = true;
			username_btn.sensitive = true;
			username_btn.icon_name = "go-next-symbolic";
		}

		private void database_insensitive() {
			// make the button insensitive
			database_btn.sensitive = false;
			database_btn.icon_name = "process-stop-symbolic";

			// make all the fields insensitive
			database.sensitive = false;
			postgresql_host.sensitive = false;
			postgresql_dbname.sensitive = false;
			postgresql_port.sensitive = false;
			postgresql_username.sensitive = false;
			postgresql_password.sensitive = false;
		}

		private void database_sensitive() {
			// make the button insensitive
			database_btn.sensitive = true;
			database_btn.icon_name = "go-next-symbolic";
			
			// make all the fields sensitive
			database.sensitive = true;
			postgresql_host.sensitive = true;
			postgresql_dbname.sensitive = true;
			postgresql_port.sensitive = true;
			postgresql_username.sensitive = true;
			postgresql_password.sensitive = true;
		}
	}
}