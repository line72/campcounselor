/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

class CampCounselor.ImageCache : GLib.Object {
	private Soup.Session session;

	public ImageCache() {
		session = new Soup.Session();

		// make sure our cache directory exists
		string path = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S,
											GLib.Environment.get_user_cache_dir(),
											"net.line72.campcounselor",
											"images");
		var f = GLib.File.new_for_path(path);
		try {
			f.make_directory_with_parents();
		} catch (GLib.Error e) {
			stdout.printf("CampCounselor.ImageCache::Error creating cache directory: %s\n", path);
		}
	}

	public string get_image(string url) {
		var checksum = GLib.Checksum.compute_for_string(GLib.ChecksumType.SHA1, url);
		// see if this is in our cache, if not
		// return the default loading image
		string path = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S,
											GLib.Environment.get_user_cache_dir(),
											"net.line72.campcounselor",
											"images",
											checksum
			);
		var f = GLib.File.new_for_path(path);
		if (!f.query_exists()) {
			return "loading.png";
		}
		
		return path;
	}

	public void build_cache(Gee.ArrayList<string> urls) {

	}
}