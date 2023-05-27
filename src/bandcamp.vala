using Soup;

class CampCounselor.BandCamp : GLib.Object {
	public static void fetchCollection(string fan_id) {
		var session = new Soup.Session();
		var message = new Soup.Message("POST", "https://bandcamp.com/api/fancollection/1/collection_items");

		session.queue_message(message, (sess, mess) => {
				stdout.printf("%s\n", mess.response_body.data);
			});

  }
}