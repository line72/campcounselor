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
		//var message = new Soup.Message("POST", "https://bandcamp.com/api/fancollection/1/wishlist_items");
		var albums = yield fetch_async("http://localhost:8081/api/fancollection/1/collection_items", fan_id);
		//var albums = yield fetch_async("https://bandcamp.com/api/fancollection/1/collection_items", fan_id);
		foreach (Album a in albums) {
			a.purchased = true;
		}
		return albums;
	}

	public async Gee.ArrayList<Album?> fetch_wishlist_async(string fan_id) {
		return yield fetch_async("http://localhost:8081/api/fancollection/1/wishlist_items", fan_id);
		//return yield fetch_async("https://bandcamp.com/api/fancollection/1/wishlist_items", fan_id);
	}

	private async Gee.ArrayList<Album?> fetch_async(string url, string fan_id) {
		var message = new Soup.Message("POST", url);

		var dt = new DateTime.now_utc();
		string token = @"$(dt.to_unix()).0::a::";
		bool done = false;

		var albums = new Gee.ArrayList<Album?>();
		
		while (!done) {
			var body = StringBuilder.free_to_bytes(
				new StringBuilder(@"{\"count\": 20, \"fan_id\": $(fan_id), \"older_than_token\": \"$(token)\"}")
				);
			//stdout.printf(@"looping $(token)\n");
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
				
				var album = new Album(
					-1,
					item.get_int_member("album_id").to_string(),
					item.get_int_member("band_id").to_string(),
					item.get_string_member("album_title"),
					item.get_string_member("band_name"),
					item.get_string_member("item_url"),
					item_art.get_string_member("thumb_url"),
					item_art.get_string_member("url")
					);
				album.created_at = DateUtils.parse(item.get_string_member("added"));
				album.updated_at = DateUtils.parse(item.get_string_member("updated"));
				albums.add(album);
			}
		} catch (Error e) {
			stdout.printf("uh-oh, error in parse_albums %s\n", e.message);
		}

		return albums;
	}
}