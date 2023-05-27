/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

class CampCounselor.BandCamp : GLib.Object {
	private Soup.Session session;
	
	public BandCamp() {
		session = new Soup.Session();
	}

	public async Gee.ArrayList<Album?> fetch_collection_async(string fan_id) {
		var message = new Soup.Message("POST", "https://bandcamp.com/api/fancollection/1/collection_items");

		string token = "1685191443.1279097::a::";
		bool done = false;

		var albums = new Gee.ArrayList<Album?>();
		
		while (!done) {
			var body = StringBuilder.free_to_bytes(
				new StringBuilder(@"{\"count\": 20, \"fan_id\": $(fan_id), \"older_than_token\": \"$(token)\"}")
				);
			stdout.printf(@"looping $(token)\n");
			message.set_request_body_from_bytes(
				"application/json",
				body
				);
			
			try {
				var request = yield session.send_and_read_async(message, 0, null);
				var a = parse_albums(request, out token);
				albums.add_all(a);

				// check for another token
				if (token == null) {
					done = true;
				}
				
			} catch (Error e) {
				stdout.printf("error %s\n", e.message);
				done = true;
			}
		}

		return albums;
	}
	
	public Gee.ArrayList<Album?> parse_albums(Bytes body, out string token) {
		var albums = new Gee.ArrayList<Album?>();

		try {
			var parser = new Json.Parser ();
			parser.load_from_data((string)body.get_data(), -1);

			var root_object = parser.get_root().get_object();

			token = root_object.get_string_member("last_token");
			
			var items = root_object.get_array_member("items");

			foreach (var i in items.get_elements()) {
				var item = i.get_object();

				var item_art = item.get_object_member("item_art");

				if (item.get_int_member("album_id") == 0)
					continue;
				
				var album = Album() {
					id = item.get_int_member("album_id").to_string(),
					band_id = item.get_int_member("band_id").to_string(),
					album = item.get_string_member("album_title"),
					artist = item.get_string_member("band_name"),
					url = item.get_string_member("item_url"),
					thumbnail_url = item_art.get_string_member("thumb_url"),
					artwork_url = item_art.get_string_member("url")
				};
				albums.add(album);
			}
		} catch (Error e) {
			stdout.printf("uh-oh, error in parse_albums %s\n", e.message);
		}

		return albums;
	}
}