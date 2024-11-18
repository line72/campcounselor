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
		private MediaPlayer.TrackInfo track_info = null;

		public MPRIS(DBusConnection connection) {
			this.connection = connection;

			MessageBoard.get_instance().add_observer(MessageBoard.MessageType.PLAYING_STARTED, this);
			MessageBoard.get_instance().add_observer(MessageBoard.MessageType.PLAYING_STOPPED, this);
			MessageBoard.get_instance().add_observer(MessageBoard.MessageType.PLAYING_PAUSED, this);
			MessageBoard.get_instance().add_observer(MessageBoard.MessageType.PLAYING_RESUMED, this);
		}

		// Observer
		public void notify_of(MessageBoard.MessageType message) {
			switch (message) {
			case MessageBoard.MessageType.PLAYING_STARTED:
				// start a timer
				GLib.Timeout.add(250, () => {
						return update();
					});
				update();
				send_property("CanPlay", new Variant.boolean(true));
				send_property("CanPause", new Variant.boolean(true));
				send_property("PlaybackStatus", new Variant.string("Playing"));
				break;
			case MessageBoard.MessageType.PLAYING_STOPPED:
				// stop our timer
				this.needs_stop = true;
				send_property("PlaybackStatus", new Variant.string("Stopped"));
				send_property("CanPlay", new Variant.boolean(false));
				send_property("CanPause", new Variant.boolean(false));
				send_property("CanGoNext", new Variant.boolean(false));
				send_property("CanGoPrevious", new Variant.boolean(false));
				break;
			case MessageBoard.MessageType.PLAYING_PAUSED:
				send_property("PlaybackStatus", new Variant.string("Paused"));
				break;
			case MessageBoard.MessageType.PLAYING_RESUMED:
				send_property("PlaybackStatus", new Variant.string("Playing"));
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
				MediaPlayer.TrackInfo ti = MediaPlayer.get_instance().get_info();
				return ti.current_track < (ti.total_tracks-1);
			}
		}
		public bool can_go_previous {
			get {
				MediaPlayer.TrackInfo ti = MediaPlayer.get_instance().get_info();
				return ti.current_track > 0;
			}
		}
		public bool can_play {
			get {
				MediaPlayer.TrackInfo ti = MediaPlayer.get_instance().get_info();
				// We can't play if we aren't playing something already
				if (ti.status == MediaPlayer.TrackInfo.TrackStatus.STOPPED &&
					ti.duration == 0) {
					return false;
				}
				return true;
			}
		}
		public bool can_pause {
			get {
				MediaPlayer.TrackInfo ti = MediaPlayer.get_instance().get_info();
				return ti.status == MediaPlayer.TrackInfo.TrackStatus.PAUSED;
			}
		}
		public bool can_seek {
			get {
				return false;
			}
		}

		public void play() throws Error {
			MediaPlayer.TrackInfo ti = MediaPlayer.get_instance().get_info();
			if (ti.status == MediaPlayer.TrackInfo.TrackStatus.PAUSED) {
				MediaPlayer.get_instance().pause();
			}
		}

		public void play_pause() throws Error {
			MediaPlayer.get_instance().pause();
		}

		public void pause() throws Error {
			MediaPlayer.TrackInfo ti = MediaPlayer.get_instance().get_info();
			if (ti.status == MediaPlayer.TrackInfo.TrackStatus.PLAYING) {
				MediaPlayer.get_instance().pause();
			}
		}

		public void next() throws Error {
			// Logic to skip to the next track
			MediaPlayer.get_instance().next();
		}

		public void previous() throws Error {
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

		public bool update() {
			MediaPlayer mp = MediaPlayer.get_instance();
			MediaPlayer.TrackInfo t = mp.get_info();

			if (this.needs_stop) {
				this.needs_stop = false;
				return false; // stop updating
			} else {
				// only send out an update if something has changed
				if (t != null && (track_info == null || !t.equal(track_info))) {
					_metadata.remove_all();

					_metadata.insert("mpris:trackid", new Variant.object_path("/org/mpris/MediaPlayer2/CampCounselorTrack"));
					var artists = new VariantBuilder(new VariantType("as"));
					artists.add("s", t.artist);
					_metadata.insert("xesam:artist", artists.end());
					_metadata.insert("xesam:title", new Variant.string(t.title));
					_metadata.insert("xesam:album", new Variant.string(t.album));
					_metadata.insert("mpris:length", new Variant.int64(t.duration / 1000));
					_metadata.insert("mpris:artUrl", new Variant.string(@"file://$(t.artwork)"));
					
					send_property("Metadata", _metadata);

					send_property("CanGoNext", can_go_next);
					send_property("CanGoPrevious", can_go_previous);
				}
				track_info = t;
			}

			// continue updating
			return true;
		}
    }
}