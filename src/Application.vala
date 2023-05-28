/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

public class CampCounselor.Application : Adw.Application {

	private CampCounselor.MainWindow? main_window;
	
	public Application () {
		Object (
				application_id: "net.line72.net.campcounselor",
				flags: ApplicationFlags.FLAGS_NONE
				);
	}
	
	protected override void activate () {
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
