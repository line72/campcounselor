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

		[GtkChild( name = "database_provider" )]
		public unowned Adw.ComboRow database;

		[GtkChild( name = "postgresql_preferences" )]
		public unowned Adw.PreferencesGroup postgresql_prefs;
		
		public SetupDialog(Gtk.Window? parent) {
			set_transient_for(parent);
			set_modal(true);

			var mgr = SettingsManager.get_instance();
			//username.text = mgr.settings.get_string("bandcamp-username");
			username.text = "";
			username.apply.connect(() => {
					stdout.printf("Apply: %s\n", username.text);
					var bandcamp = new BandCamp(mgr.settings.get_string("bandcamp-url"));
					var username = username.text;
					bandcamp.fetch_fan_id_from_username.begin(
						username, (obj, res) => {
							var fan_id = bandcamp.fetch_fan_id_from_username.end(res);

							if (fan_id == null) {
								// show an error
								stdout.printf("Invalid fan id\n");
							} else {
								stdout.printf("Fan Id=%s\n", fan_id);
								// save it to settings
								mgr.settings.set_string("bandcamp-fan-id", fan_id);
								// move to page 2
								navigation.push_by_tag("page-2");
							}
						});
				});

			var db = mgr.settings.get_string("database-backend");
			if (db == "PostgreSQL") {
				database.set_selected(1);
			} else {
				database.set_selected(0);
			}

			if (db == "PostgreSQL") {
				postgresql_prefs.visible = true;
			} else {
				postgresql_prefs.visible = false;
			}
		}
	}
}