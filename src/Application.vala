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
		{ "refresh", refresh_cb },
		{ "preferences", preferences_cb },
		{ "about", about_cb },
		{ "quit", quit_cb }
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
		command_line.get_options_dict ();

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
			try {
				var resource = GLib.Resource.load("data/net.line72.campcounselor.gresource");
				GLib.resources_register(resource);
			} catch (GLib.Error e) {
				stdout.printf("Warning! Unable to load gresource file\n");
			}
		}
		add_action_entries(actions, this);

		// accels
		this.set_accels_for_action ("app.quit", {"<Control>q"});
		this.set_accels_for_action ("app.refresh", {"<Primary>R", "F5"});

		// Load the default stylesheet
		Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (),
												   provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
		provider.load_from_resource ("/net/line72/campcounselor/stylesheet/default.css");
		
		try {
			add_new_window();
		} catch (GLib.Error e) {
			var d = new Gtk.AlertDialog(@"Unable to open database. Please check permissions of $(Environment.get_user_state_dir())");
			d.modal = true;
			d.choose.begin(this.main_window, null, (obj, res) => {
					try {
						d.choose.end(res);
					} catch (GLib.Error e) {
					}
					
					this.quit();
				});

		}
	}
	
	void about_cb(SimpleAction action, Variant? parameter) {
		string[] developers = {
			"Marcus Dillavou <line72@line72.net>"
		};
		
		var about = new Adw.AboutWindow () {
				transient_for = this.main_window,
				application_name = "Camp Counselor",
				application_icon = "net.line72.campcounselor-icon",
				developer_name = _("Marcus Dillavou"),
				version = Config.PACKAGE_VERSION,
				website = "https://line72.net/software/camp-counselor/",
				issue_url = "https://github.com/line72/campcounselor/issues/new",
				developers = developers,
				copyright = _("© 2023 Marcus Dillavou"),
				license_type = Gtk.License.GPL_3_0
		};
		
		about.present ();
	}

	void refresh_cb(SimpleAction action, Variant? parameter) {
		this.main_window.refresh();
	}
	
	void preferences_cb(SimpleAction action, Variant? parameter) {
		var d = new SetupDialog(this.main_window);
		d.close_request.connect((response) => {
				return false;
			});
		d.show();
		
	}
	
	void quit_cb(SimpleAction action, Variant? parameter) {
		this.main_window.destroy();
	}
	
	private void add_new_window () throws GLib.Error {
		if (main_window == null) {
			main_window = new CampCounselor.MainWindow (this);
			add_window(main_window);
			main_window.present();
		}
	}
	
	public static int main (string[] args) {
		var app = new CampCounselor.Application ();
		return app.run (args);
	}
}
