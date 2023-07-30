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
	
	private const OptionEntry[] options = {
		{ "version",     'v', 0, OptionArg.NONE,   null, N_("Print the current version") },
		{}
	};

	public Application () {
		Object (
				application_id: Config.APP_ID,
				resource_base_path: "/net/line72/campcounselor",
				flags: ApplicationFlags.HANDLES_COMMAND_LINE
			);
	}

	static construct {
		provider = new Gtk.CssProvider();
	}

	construct {
		add_main_option_entries (options);
	}

	public override int command_line (ApplicationCommandLine command_line) {
		var options = command_line.get_options_dict ();

		activate ();

		return 0;
	}

	public override int handle_local_options (VariantDict options) {
		if ("version" in options) {
			stdout.printf ("%s %s\n", Config.PACKAGE_NAME, Config.PACKAGE_VERSION);
			return 0;
		}

		return -1;
	}

	
	protected override void activate () {
		// register our resorces
		try {
			var resource = GLib.Resource.load(Config.DATADIR + "/" + Config.PACKAGE_NAME + "/net.line72.campcounselor.gresource");
			GLib.resources_register(resource);
		} catch (GLib.Error e) {
			var resource = GLib.Resource.load("data/net.line72.campcounselor.gresource");
			GLib.resources_register(resource);
		}
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
