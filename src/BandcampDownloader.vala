/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	class BandcampDownloader : GLib.Object {
		public class Track : GLib.Object {
			public string name;
			public string url;
			public int64 num;
			public bool cached = false;
			
			public Track(string name, string url, int64 num) {
				this.name = name;
				this.url = url;
				this.num = num;
			}
		}
		
		/**
		 * Parse the URL and find any vailable
		 *  tracks
		 */
		public static async Gee.ArrayList<BandcampDownloader.Track>? parse_tracks(string url) {
			stdout.printf("BandcampDownloader.parseTracks\n");
			var session = new Soup.Session();
			
			var message = new Soup.Message("GET", url);
			try {
				var request = yield session.send_and_read_async(message, 0, null);
				unowned char[] body = (char[])request.get_data();
				int s = (int)request.get_size();
				var doc = Html.Doc.read_memory(body, s, url,
											   null, Html.ParserOption.NOWARNING | Html.ParserOption.NOERROR);
				var root = doc->get_root_element();
				if (root != null) {
					// Traverse to find data-tralbum attribute in script tags
					Xml.Node *iter = root->children;
					while (iter != null) {
						if (iter->type == Xml.ElementType.ELEMENT_NODE && iter->name == "head") {
							Xml.Node *iter2 = iter->children;
							while (iter2 != null) {
								if (iter2->type == Xml.ElementType.ELEMENT_NODE &&
									iter2->name == "script" &&
									iter2->get_prop("data-tralbum") != null) {

									var tralbum = iter2->get_prop("data-tralbum");

									var tracks = BandcampDownloader.do_parse_tracks(tralbum);

									// !mwd - SORT TRACKS
									
									return tracks;
								}
								iter2 = iter2->next;
							}
						}
						iter = iter->next;
					}
				} else {
					stdout.printf("Error: BandcampmDownloader.parse_tracks: No root?\n");
				}
			} catch (Error e) {
				stdout.printf(@"Error: BandcampDownloader.parse_tracks: $(e.message)\n");
				return null;
			}

			return null;
		}

		/**
		 * Get the path to a cached track.
		 * If the track isn't cached yet,
		 *  start downloading it
		 */
		public static async string cached_track() {
			return "";
		}


		private static Gee.ArrayList<BandcampDownloader.Track>? do_parse_tracks(string blob) {
			try {
				var parser = new Json.Parser();
				parser.load_from_data(blob, -1);

				var root_object = parser.get_root();
				if (root_object == null) {
					stdout.printf("BandcampDownloader.do_parse_tracks: Invalid JSON\n");
					return null;
				}

				var track_info = root_object.get_object().get_array_member("trackinfo");
				if (track_info == null) {
					stdout.printf("BandcampDownloader.do_parse_tracks: Unable to find trackinfo\n");
					return null;
				}

				// loop through, creating our tracks
				var tracks = new Gee.ArrayList<BandcampDownloader.Track>();
				
				foreach (var t in track_info.get_elements()) {
					var item = t.get_object();

					var track = new BandcampDownloader.Track(item.get_string_member("title"),
															 item.get_object_member("file").get_string_member("mp3-128"),
															 item.get_int_member("track_num"));
					tracks.add(track);
				}

				return tracks;
			} catch (GLib.Error e) {
				stdout.printf(@"Error parsing bandcamp info: $(e.message)\n");
			}
			return null;
		}
	}
}