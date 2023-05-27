/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

class CampCounselor.BandCamp : GLib.Object {
	public static Gee.ArrayList<Album?> fetchCollection(string fan_id) {
		var session = new Soup.Session();
		var message = new Soup.Message("POST", "https://bandcamp.com/api/fancollection/1/collection_items");

		var body = StringBuilder.free_to_bytes(
			new StringBuilder("{\"count\": 20, \"fan_id\": 1057301, \"older_than_token\": \"1685191443.1279097::a::\"}")
			);
		message.set_request_body_from_bytes(
			"application/json",
			body
			);
		// session.queue_message(message, (sess, mess) => {
		// 		stdout.printf("%s\n", mess.response_body.data);
		// 	});

		var albums = new Gee.ArrayList<Album?>();
		try {
			var resp = session.send_and_read(message);

			//stdout.printf((string)resp.get_data());
			
			var parser = new Json.Parser ();
			parser.load_from_data((string)resp.get_data(), -1);

			var root_object = parser.get_root().get_object();
			var items = root_object.get_array_member("items");

			foreach (var i in items.get_elements()) {
				var item = i.get_object();
				
				var album = Album() {
					id = item.get_int_member("album_id").to_string(),
					band_id = item.get_int_member("band_id").to_string(),
					album = item.get_string_member("album_title"),
					artist = item.get_string_member("band_name"),
					url = item.get_string_member("item_url")
				};
				albums.add(album);
			}
		} catch (Error e) {
			stdout.printf("uh-oh, error %s\n", e.message);
		}
			
		return albums;
	}
}