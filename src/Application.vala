/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

public class CampCounselor.Application : Adw.Application, Observer {

	private CampCounselor.MainWindow? main_window;
	private static Gtk.CssProvider provider;
	private uint inhibit_request = 0;

	const ActionEntry[] actions = {
		/*{ "action name", cb to connect to "activate" signal, parameter type,
		  initial state, cb to connect to "change-state" signal } */
		{ "refresh", refresh_cb },
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
		MessageBoard.get_instance().add_observer(MessageBoard.MessageType.PLAYING_STARTED, this);
		MessageBoard.get_instance().add_observer(MessageBoard.MessageType.PLAYING_STOPPED, this);
		MessageBoard.get_instance().add_observer(MessageBoard.MessageType.PLAYING_RESUMED, this);
		MessageBoard.get_instance().add_observer(MessageBoard.MessageType.PLAYING_PAUSED, this);
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

	public override bool dbus_register (DBusConnection connection, string object_path) throws Error {
		// We must chain up to the parent class:
		base.dbus_register (connection, object_path);
		
		// Register the MPRIS interface on the D-Bus
		if (connection != null) {
			connection.register_object("/org/mpris/MediaPlayer2", new MPRIS());
		}
		
		return true;
	}

	public override void dbus_unregister (DBusConnection connection, string object_path) {
		// Unregister the object from D-Bus if needed
		if (connection != null) {
			//connection.unregister_object("/org/mpris/MediaPlayer2");
		}
		
		base.dbus_unregister (connection, object_path);
	}
	
	public void notify_of(MessageBoard.MessageType message) {
		switch (message) {
		case MessageBoard.MessageType.PLAYING_STARTED:
			this.inhibit_request = inhibit(this.main_window, Gtk.ApplicationInhibitFlags.SUSPEND, "Music Playing");
			break;
		case MessageBoard.MessageType.PLAYING_RESUMED:
			this.inhibit_request = inhibit(this.main_window, Gtk.ApplicationInhibitFlags.SUSPEND, "Music Playing");
			break;
		case MessageBoard.MessageType.PLAYING_STOPPED:
			uninhibit(this.inhibit_request);
			break;
		case MessageBoard.MessageType.PLAYING_PAUSED:
			uninhibit(this.inhibit_request);
			break;
		default:
			break;
		}
	}

	void about_cb(SimpleAction action, Variant? parameter) {
		string[] developers = {
			"Marcus Dillavou <line72@line72.net>"
		};
		
		var about = new Adw.AboutWindow () {
				transient_for = this.main_window,
				application_name = "Camp Counselor",
				application_icon = "net.line72.campcounselor",
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
	
	void quit_cb(SimpleAction action, Variant? parameter) {
		this.main_window.destroy();
	}

	private void register_all_types() {
		Type[] custom_types = {
			typeof(MediaBar),
			typeof(AlbumListItem),
			typeof(AlbumEditComment),
			typeof(SetupDialog)
		};

		foreach (var type in custom_types) {
			type.ensure();
		}
	}
	
	private void add_new_window () throws GLib.Error {
		register_all_types();

		if (main_window == null) {
			main_window = new CampCounselor.MainWindow (this);
			add_window(main_window);
			main_window.present();
		}
	}
	
	public static int main (string[] args) {
		var app = new CampCounselor.Application ();
		Gst.init(ref args);
		return app.run (args);
	}
}
