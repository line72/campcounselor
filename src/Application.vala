/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

public class CampCounselor.Application : Adw.Application {

	private CampCounselor.MainWindow? main_window;
	private static Gtk.CssProvider provider;
	
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
		var resource = GLib.Resource.load("data/net.line72.campcounselor.gresource");
		GLib.resources_register(resource);

		// Load the default stylesheet
		Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (),
												   provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
		provider.load_from_resource ("/net/line72/campcounselor/stylesheet/default.css");
		
		
		add_new_window();
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
