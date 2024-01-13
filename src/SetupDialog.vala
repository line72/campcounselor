/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	[GtkTemplate (ui = "/net/line72/campcounselor/ui/setupdialog.ui")]
	public class SetupDialog : Adw.PreferencesWindow {
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
			username.text = mgr.settings.get_string("bandcamp-fan-id");
		}
	}
}