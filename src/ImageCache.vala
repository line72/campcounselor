/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

class CampCounselor.ImageCache : GLib.Object {
	private Soup.Session session;
	private string cache_dir;

	public ImageCache() {
		session = new Soup.Session();

		// make sure our cache directory exists
		var f = File.new_build_filename(
			Environment.get_user_cache_dir(),
			"net.line72.campcounselor",
			"images"
			);
		this.cache_dir = f.get_path();
		
		try {
			f.make_directory_with_parents();
		} catch (GLib.Error e) {
			stdout.printf("CampCounselor.ImageCache::Error creating cache directory: %s\n", this.cache_dir);
		}
	}

	public bool exists(string name) {
		var fcover = File.new_build_filename(
			this.cache_dir,
			name
			);
		return fcover.query_exists();
	}

	public string get_path(string name) {
		var fcover = File.new_build_filename(
			this.cache_dir,
			name
			);
		return fcover.get_path();
	}
	
	public async string get_image(string url, string name) throws Error {
		var message = new Soup.Message("GET", url);

		var request = yield session.send_and_read_async(message, 0, null);
		var f = File.new_build_filename(this.cache_dir, name);
		var f2 = f.create_readwrite(FileCreateFlags.PRIVATE);
		var stream = f2.output_stream;
		stream.write_bytes(request);
		stream.close();
		
		return f.get_path();
	}
}