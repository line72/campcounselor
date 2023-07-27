/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

public class CampCounselor.Application : Adw.Application {

	private CampCounselor.MainWindow? main_window;
	private static Gtk.CssProvider provider;

	const ActionEntry[] actions = {
		/*{ "action name", cb to connect to "activate" signal, parameter type,
		  initial state, cb to connect to "change-state" signal } */
		{ "about", about_cb }
	};
	
	public Application () {
		Object (
				application_id: "net.line72.net.campcounselor",
				flags: ApplicationFlags.FLAGS_NONE
				);
	}

	static construct {
		provider = new Gtk.CssProvider();
	}
	
	protected override void activate () {
		// register our resorces
		var resource = GLib.Resource.load(Config.DATADIR + "/" + Config.PACKAGE_NAME + "/net.line72.campcounselor.gresource");
		GLib.resources_register(resource);
		add_action_entries(actions, this);

		// Load the default stylesheet
		Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (),
												   provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
		provider.load_from_resource ("/net/line72/campcounselor/stylesheet/default.css");
		
		
		add_new_window();
	}
	
	void about_cb(SimpleAction action, Variant? parameter) {
		stdout.printf("ABOUT\n");
	}
	
	private void add_new_window () {
		if (main_window == null) {
			main_window = new CampCounselor.MainWindow (this);
			add_window(main_window);
		}
	}
	
	public static int main (string[] args) {
		var app = new CampCounselor.Application ();
		return app.run (args);
	}
}
