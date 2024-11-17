/*
 * (c) 2024 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	[DBus(name = "org.mpris.MediaPlayer2")]
	public interface MediaPlayer2 : Object {
		public abstract bool can_quit { get; }
		public abstract bool can_raise { get; }
		public abstract bool has_track_list { get; }
		public abstract string desktop_entry { owned get; }
		public abstract string identity { owned get; }
		public abstract string[] supported_uri_schemes { owned get; }
		public abstract string[] supported_mime_types { owned get; }
		public abstract void quit() throws Error;
		public abstract void raise() throws Error;
	}

	[DBus(name = "org.mpris.MediaPlayer2.Player")]
	public interface MediaPlayer2Player : Object {
		public abstract bool can_control { get; }
		public abstract bool can_go_next { get; }
		public abstract bool can_go_previous { get; }
		public abstract bool can_play { get; }
		public abstract bool can_pause { get; }
		public abstract bool can_seek { get; }
		public abstract void play() throws Error;
		public abstract void play_pause() throws Error;
		public abstract void pause() throws Error;
		public abstract void next() throws Error;
		public abstract void previous() throws Error;
		public abstract void seek(int64 offset) throws Error;
		public abstract bool shuffle { get; set; }
		public abstract double volume { get; set; }
		public abstract int64 position { get; }
		public abstract string playback_status { owned get; }  // "Playing", "Paused", "Stopped"
		public abstract HashTable<string, Variant> metadata { owned get; }  // Metadata like artist, title, album
	}

	public class MPRIS : GLib.Object, MediaPlayer2, MediaPlayer2Player, Observer {
		private HashTable<string, Variant> _metadata = new HashTable<string, Variant> (str_hash, str_equal);
		private unowned DBusConnection connection;
		private bool needs_stop = false;

		public MPRIS(DBusConnection connection) {
			this.connection = connection;

			MessageBoard.get_instance().add_observer(MessageBoard.MessageType.PLAYING_STARTED, this);
			MessageBoard.get_instance().add_observer(MessageBoard.MessageType.PLAYING_STOPPED, this);
		}

		// Observer
		public void notify_of(MessageBoard.MessageType message) {
			switch (message) {
			case MessageBoard.MessageType.PLAYING_STARTED:
				// start a timer
				GLib.Timeout.add(250, () => {
						return update();
					});
				break;
			case MessageBoard.MessageType.PLAYING_STOPPED:
				// stop our timer
				this.needs_stop = true;
				break;
			default:
				break;
			}
		}
		
		// MediaPlayer2 Properties
		public bool can_quit { get { return false; } }
		public bool can_raise { get { return false; } }
		public bool has_track_list { get { return false; } }
		public string desktop_entry { owned get { return Config.APP_ID; } }
		public string identity { owned get { return "Camp Counselor"; } }
		public string[] supported_uri_schemes {
			owned get {
				return {"file", "smb"};
			}
		}
		public string[] supported_mime_types {
			owned get {
				return {"audio/*"};
			}
		}
	
		// MediaPlayer2 Methods
		public void quit() throws Error {
		}

		public void raise() throws Error {
			// Optionally bring the app window to the front if supported
		}

		// MediaPlayer2Player Methods
		public bool can_control { get { return true; } }
		public bool can_go_next {
			get {
				return true;
			}
		}
		public bool can_go_previous {
			get {
				return true;
			}
		}
		public bool can_play {
			get {
				return true;
			}
		}
		public bool can_pause {
			get {
				return true;
			}
		}
		public bool can_seek {
			get {
				return false;
			}
		}

		public void play() throws Error {
			stdout.printf("Play\n");
			MediaPlayer.get_instance().pause();
		}

		public void play_pause() throws Error {
			stdout.printf("Play\n");
			MediaPlayer.get_instance().pause();
		}

		public void pause() throws Error {
			stdout.printf("Pause\n");
			MediaPlayer.get_instance().pause();
		}

		// public override void Stop() {
		// 	stdout.printf("Stop\n");
		// 	MediaPlayer.TrackInfo ti = MediaPlayer.get_instance().get_info();
		// 	if (ti.status == MediaPlayer.TrackInfo.TrackStatus.PLAYING) {
		// 		MediaPlayer.get_instance().pause();
		// 	}
		// }

		public void next() throws Error {
			stdout.printf("Next\n");
			// Logic to skip to the next track
			MediaPlayer.get_instance().next();
		}

		public void previous() throws Error {
			stdout.printf("Previous\n");
			// Logic to go to the previous track
			MediaPlayer.get_instance().previous();
		}

		public void seek(int64 offset) throws Error {
			// Logic to adjust playback position
		}

		// MediaPlayer2Player Properties
		public bool shuffle {
			get {
				return false;
			}
			set {
			}
		}

		public double volume {
			get {
				return 1.0;
			}
			set {
			}
		}
		
		public int64 position {
			get {
				MediaPlayer.TrackInfo ti = MediaPlayer.get_instance().get_info();
				return ti.current_position;
			}
		}

		public string playback_status {
			owned get {
				MediaPlayer.TrackInfo ti = MediaPlayer.get_instance().get_info();
				if (ti.status == MediaPlayer.TrackInfo.TrackStatus.STOPPED) {
					return "Stopped";
				} else if (ti.status == MediaPlayer.TrackInfo.TrackStatus.PLAYING) {
					return "Playing";
				} else {
					return "Paused";
				}
			}
		}

		public HashTable<string, Variant> metadata {
			owned get {
				return _metadata;
			}
		}

		private void send_property(string name, Variant variant) {
			stdout.printf("send_property");
			var builder = new VariantBuilder(new VariantType("a{sv}"));
			builder.add("{sv}", name, variant);
			send_properties(builder);
		}

		private void send_properties(VariantBuilder builder) {
			var invalid = new VariantBuilder(new VariantType("as"));
			try {
				this.connection.emit_signal(
					null,
					"/org/mpris/MediaPlayer2",
					"org.freedesktop.DBus.Properties",
					"PropertiesChanged",
					new Variant(
						"(sa{sv}as)",
						"org.mpris.MediaPlayer2.Player",
						builder,
						invalid
						)
					);
			} catch (Error e) {
				warning("Sending property to MPRIS failed: %s\n", e.message);
			}
		}
			// owned get {
			// 	MediaPlayer.TrackInfo ti = MediaPlayer.get_instance().get_info();
			
			// 	var metadata = new GLib.VariantDict();

		
			// 	// // Generate track ID
			// 	// string track_info = "%s-%s-%d-%s".printf(ti.artist, ti.album, ti.current_track, ti.title);
			// 	// GLib.Checksum checksum = new GLib.Checksum(GLib.ChecksumType.SHA256);
			// 	// checksum.update(track_info.data, track_info.length);
			// 	// string track_id = checksum.get_string();
			// 	// stdout.printf(@"track_id $(track_id)\n");
		
			// 	// Track ID (must be an object path)
			// 	metadata.insert_value("mpris:trackid", new GLib.Variant.object_path("/org/mpris/MediaPlayer2/Track1"));

			// 	// Title
			// 	if (ti.title != null) {
			// 		metadata.insert_value("xesam:title", new GLib.Variant.string(ti.title));
			// 	}

			// 	// Artist (array of strings)
			// 	if (ti.artist != null) {
			// 		metadata.insert_value(
			// 			"xesam:artist",
			// 			new GLib.Variant.array(GLib.VariantType.STRING, { new GLib.Variant.string(ti.artist) })
			// 			);
			// 	}

			// 	// Album
			// 	if (ti.album != null) {
			// 		metadata.insert_value("xesam:album", new GLib.Variant.string(ti.album));
			// 	}

			// 	// Length in microseconds
			// 	metadata.insert_value("mpris:length", new GLib.Variant.int64(ti.duration));

			// 	// Return the metadata as a{sv}
			// 	return metadata.end();
			// }
		// }

		public bool update() {
			stdout.printf("update\n");
			MediaPlayer mp = MediaPlayer.get_instance();
			MediaPlayer.TrackInfo t = mp.get_info();

			if (this.needs_stop) {
				this.needs_stop = false;
				return false; // stop updating
			} else {
				stdout.printf("metadata\n");
				_metadata.remove_all();

				_metadata.insert("xesam:artist", new Variant.string(t.artist));
				_metadata.insert("xesam:title", new Variant.string(t.title));
				_metadata.insert("xesam:album", new Variant.string(t.album));
				_metadata.insert("xesam:length", new Variant.int64(t.duration));

				stdout.printf("sending\n");
				send_property("Metadata", _metadata);
			}

			// continue updating
			return true;
		}
    }
}