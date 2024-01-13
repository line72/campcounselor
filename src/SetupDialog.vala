/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	[GtkTemplate (ui = "/net/line72/campcounselor/ui/setupdialog.ui")]
	public class SetupDialog : Adw.Window {
		[GtkChild( name = "username_lbl" )]
		public unowned Adw.EntryRow username;

		[GtkChild( name = "database_provider" )]
		public unowned Adw.ComboRow database;

		// [GtkChild( name = "postgresql_preferences" )]
		// public unowned Adw.PreferencesGroup postgresql_prefs;
		
		public SetupDialog(Gtk.Window? parent) {
			set_transient_for(parent);
			set_modal(true);

			// var mgr = SettingsManager.get_instance();
			// username.text = mgr.settings.get_string("bandcamp-fan-id");

			// var db = mgr.settings.get_string("database-backend");
			// if (db == "PostgreSQL") {
			// 	database.set_selected(1);
			// } else {
			// 	database.set_selected(0);
			// }

			// if (db == "PostgreSQL") {
			// 	postgresql_prefs.visible = true;
			// } else {
			// 	postgresql_prefs.visible = false;
			// }
		}
	}
}