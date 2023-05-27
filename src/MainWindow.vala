/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

public class CampCounselor.MainWindow : Adw.ApplicationWindow {
	public MainWindow (CampCounselor.Application application) {
		Object (
			title: "Camp Counselor",
			application: application,
			resizable: true
			);
	}

	construct {
		present ();

		var bandcamp = new BandCamp();
		// var albums = bandcamp.fetch_collection("1057301");
		// foreach (Album? album in albums) {
		// 	stdout.printf(@"[$(album.id)] $(album.artist) - $(album.album)\n");
		// }

		bandcamp.fetch_collection_async("", (albums) => {
				foreach (Album? album in albums) {
					stdout.printf(@"[$(album.id)] $(album.artist) - $(album.album)\n");
				}
			});
	}
}