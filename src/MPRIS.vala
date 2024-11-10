/*
 * (c) 2024 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	public interface MediaPlayer2 : Object {
		public abstract bool CanQuit { get; }
		public abstract bool CanRaise { get; }
		public abstract bool HasTrackList { get; }
		public abstract string Identity { owned get; }
		public abstract void Quit();
		public abstract void Raise();

		public abstract void Play();
		public abstract void Pause();
		public abstract void Stop();
		public abstract void Next();
		public abstract void Previous();
		public abstract void Seek(int64 offset);
		public abstract int64 Position { get; }
		public abstract string PlaybackStatus { owned get; }  // "Playing", "Paused", "Stopped"
		public abstract GLib.Variant Metadata { owned get; }  // Metadata like artist, title, album
	}

	[DBus(name = "org.mpris.MediaPlayer2")]
	public class MPRIS : GLib.Object, MediaPlayer2 {
		// MediaPlayer2 Properties
		public override bool CanQuit { get { return false; } }
		public override bool CanRaise { get { return false; } }
		public override bool HasTrackList { get { return false; } }
		public override string Identity { owned get { return "Camp Counselor"; } }
	
		// MediaPlayer2 Methods
		public override void Quit() {
		}

		public override void Raise() {
			// Optionally bring the app window to the front if supported
		}

		// MediaPlayer2Player Methods
		public override void Play() {
			MediaPlayer.get_instance().pause();
		}

		public override void Pause() {
			MediaPlayer.get_instance().pause();
		}

		public override void Stop() {
			MediaPlayer.TrackInfo ti = MediaPlayer.get_instance().get_info();
			if (ti.status == MediaPlayer.TrackInfo.TrackStatus.PLAYING) {
				MediaPlayer.get_instance().pause();
			}
		}

		public override void Next() {
			// Logic to skip to the next track
			MediaPlayer.get_instance().next();
		}

		public override void Previous() {
			// Logic to go to the previous track
			MediaPlayer.get_instance().previous();
		}

		public override void Seek(int64 offset) {
			// Logic to adjust playback position
		}

		// MediaPlayer2Player Properties
		public override int64 Position {
			get {
				MediaPlayer.TrackInfo ti = MediaPlayer.get_instance().get_info();
				return ti.current_position;
			}
		}

		public override string PlaybackStatus {
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

		public override GLib.Variant Metadata {
			owned get {
				MediaPlayer.TrackInfo ti = MediaPlayer.get_instance().get_info();
			
				var metadata = new GLib.VariantDict();
			
				// Generate track ID
				string track_info = "%s-%s-%d-%s".printf(ti.artist, ti.album, ti.current_track, ti.title);
				GLib.Checksum checksum = new GLib.Checksum(GLib.ChecksumType.SHA256);
				checksum.update(track_info.data, track_info.length);
				string track_id = checksum.get_string();
			
				metadata.insert_value("mpris:trackid", new GLib.Variant(track_id));
				metadata.insert_value("xesam:title", new GLib.Variant(ti.title));
				metadata.insert_value("xesam:artist", new GLib.Variant.array(GLib.VariantType.STRING, new GLib.Variant[] { new GLib.Variant(ti.artist) }));
				metadata.insert_value("xesam:album", new GLib.Variant(ti.album));
				metadata.insert_value("mpris:length", new GLib.Variant.int64(ti.duration));  // Track length in microseconds
			
				return metadata.end();
			}
		}
	}
}