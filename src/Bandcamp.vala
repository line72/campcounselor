/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

class CampCounselor.BandCamp : GLib.Object {
	private Soup.Session session;
	private string url;
	
	public BandCamp(string url) {
		session = new Soup.Session();
		this.url = url;
	}

	public async Gee.ArrayList<Album?> fetch_collection_async(string fan_id) {
		var albums = yield fetch_async(@"$(this.url)/api/fancollection/1/collection_items", fan_id);
		foreach (Album a in albums) {
			a.purchased = true;
		}
		return albums;
	}

	public async Gee.ArrayList<Album?> fetch_wishlist_async(string fan_id) {
		return yield fetch_async(@"$(this.url)/api/fancollection/1/wishlist_items", fan_id);
	}

	public async string? fetch_fan_id_from_username(string username) {
		var url = @"$(this.url)/$(username)";
		var message = new Soup.Message("GET", url);

		try {
			var request = yield session.send_and_read_async(message, 0, null);
			unowned char[] body = (char[])request.get_data();
			int s = (int)request.get_size();
			var doc = Html.Doc.read_memory(body, s, url,
										   null, Html.ParserOption.NOWARNING | Html.ParserOption.NOERROR);

			var root = doc->get_root_element();
			if (root != null) {
				// iterate through the children
				Xml.Node *iter = root->children;
				while (iter != null) {
					if (iter->type == Xml.ElementType.ELEMENT_NODE && iter->name == "body") {
						Xml.Node *iter2 = iter->children;
						while (iter2 != null) {
							// search of a div whose id is pagedata
							if (iter2->type == Xml.ElementType.ELEMENT_NODE &&
								iter2->name == "div" &&
								iter2->get_prop("id") == "pagedata") {

								// grab the data-blob
								//  this is a bunch of JSON that has
								//  interesting stuff in it
								var blob = iter2->get_prop("data-blob");
								
								// parse the JSON
								var parser = new Json.Parser ();
								parser.load_from_data(blob, -1);

								var root_object = parser.get_root();
								if (root_object == null) {
									stdout.printf("Bandcamp.fetch_fan_id_from_username: Invalid JSON\n");
									return null;
								}

								var fan_data = root_object.get_object().get_object_member("fan_data");
								if (fan_data == null) {
									stdout.printf("Bandcamp.fetch_fan_id_from_username: Missing fan_data\n");
									return null;
								}

								var fan_id = fan_data.get_int_member("fan_id");
								return fan_id.to_string();
							}
							iter2 = iter2->next;
						}
					}
					iter = iter->next;
				}
				
				return null;
			} else {
				return null;
			}

		} catch (Error e) {
			stdout.printf("Error: Bandcamp.fetch_fan_id_from_username: %s\n", e.message);
			return null;
		}
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
				var a = parse_albums(request, ref token);
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
	
	public Gee.ArrayList<Album?> parse_albums(Bytes body, ref string token) {
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