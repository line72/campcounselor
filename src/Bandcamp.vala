/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

class CampCounselor.BandCamp : GLib.Object {
	public static void fetchCollection(string fan_id) {
		var session = new Soup.Session();
		var message = new Soup.Message("POST", "https://bandcamp.com/api/fancollection/1/collection_items");

		var body = StringBuilder.free_to_bytes(
			new StringBuilder("{\"count\": 20, \"fan_id\": 1057301, \"older_than_token\": \"1685191443.1279097::a::\"}")
			);
		message.set_request_body_from_bytes(
			"application/json",
			body
			);

		try {
			var resp = session.send_and_read(message);

			var parser = new Json.Parser ();
			parser.load_from_data((string)resp.get_data(), -1);

			var root_object = parser.get_root().get_object();
			
			
			stdout.printf("resp-%s\n", (string)resp.get_data());
		} catch (Error e) {
			stdout.printf("uh-oh, error %s\n", e.message);
		}
		// session.queue_message(message, (sess, mess) => {
		// 		stdout.printf("%s\n", mess.response_body.data);
		// 	});
		
	}
}