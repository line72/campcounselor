using Gtk;

class CampCounselor.Main : GLib.Object {
	public static int main(string[] args) {
		var app = new Gtk.Application("net.line72.campcounselor",
									  GLib.ApplicationFlags.FLAGS_NONE);
		app.activate.connect(() => {
				var window = new Gtk.ApplicationWindow(app);
				window.present();
			});

		return app.run(args);
  }
}
