/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	[GtkTemplate (ui = "/net/line72/campcounselor/ui/setupdialog.ui")]
	public class SetupDialog : Adw.Window {
		[GtkChild( name = "setup_navigation_view" )]
		public unowned Adw.NavigationView navigation;
		
		[GtkChild( name = "username_lbl" )]
		public unowned Adw.EntryRow username;

		[GtkChild( name = "username_toast" )]
		public unowned Adw.ToastOverlay username_toast;

		[GtkChild( name = "username_btn" )]
		public unowned Gtk.Button username_btn;

		[GtkChild( name = "database_provider" )]
		public unowned Adw.ComboRow database;

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
			//username.text = mgr.settings.get_string("bandcamp-username");
			username.text = "";
			connect_username(mgr);

			connect_database(mgr);
		}

		private void connect_username(SettingsManager mgr) {
			username.apply.connect(() => {
				});
			username_btn.clicked.connect(() =>{
					username.sensitive = false;
					username_btn.sensitive = false;
					username_btn.icon_name = "process-stop-symbolic";
					
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
								username_toast.add_toast(t);
								
								username.sensitive = true;
								username_btn.sensitive = true;
								username_btn.icon_name = "go-next-symbolic";
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
	}
}