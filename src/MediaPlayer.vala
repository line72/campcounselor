/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	public class MediaPlayer : GLib.Object {
		private static MediaPlayer media_player = null;
		private Gee.ArrayList<BandcampDownloader.Track> tracks;
		private string artwork;
		private int current_track;
		private bool playing = false;
		Gst.Element playbin = null;
		
		private MediaPlayer() {
			playbin = Gst.ElementFactory.make("playbin", "audio_player");

			Gst.Bus bus = playbin.get_bus();
			bus.add_watch(0, (bus1, message) => {
				stdout.printf(@"got bus message: $(message.type.get_name())\n");
				switch (message.type) {
					// case Gst.MessageType.STATE_CHANGED:
					// 	  // we don't have to listen to this, but if we do
					// 	  // we need to ONLY react to ones from the correct src
					// 	  //  not other internal ones. Reacting to the internal
					// 	  //  ones will break the pipeline. (this doesn't seem
					// 	  //  to be true)
					// 	  Gst.Element src = (Gst.Element)message.src;  // Get the source of the message
					// 	  if (src == playbin) {
					// 		  Gst.State old_state;
					// 		  Gst.State new_state;
					// 		  Gst.State pending_state;
					
					// 		  message.parse_state_changed (out old_state, out new_state, out pending_state);
					// 		  stdout.printf("Pipeline state changed from %s to %s:\n",
					// 						Gst.Element.state_get_name (old_state),
					// 						Gst.Element.state_get_name (new_state));
					// 	  }
					// 	  break;
				case Gst.MessageType.EOS: // end of stream
					stdout.printf("Song finished\n");
					playbin.set_state(Gst.State.NULL);  // Reset pipeline state

					// play next if we can
					this.next();
					
					break;
				case Gst.MessageType.ERROR:
					Error err;
					string debug;
					message.parse_error (out err, out debug);
					stdout.printf(@"Error playing: $(debug)\n");
					break;
				default:
					break;
				}

				return true; // return true to keep listening
			});

		}

		public static MediaPlayer getInstance() {
			if (media_player == null) {
				media_player = new MediaPlayer();
			}
			return media_player;
		}

		public void set_tracks(Gee.ArrayList<BandcampDownloader.Track> tracks,
							   string artwork) {
			playbin.set_state(Gst.State.NULL);  // Reset pipeline state
			
			this.tracks = tracks;
			this.artwork = artwork;

			this.current_track = 0;
			this.playing = false;
		}

		
		public void play() {
			if (this.current_track > 0) {
				BandcampDownloader.Track t = this.tracks.get(this.current_track);
				this.playbin.set("uri", t.url);
				this.playbin.set_state(Gst.State.PLAYING);
			}
		}

		public void pause() {
			
		}

		public void next() {
			if (this.current_track < this.tracks.size) {
				this.current_track += 1;
				play();
			}
		}

		public void previous() {
			if (this.current_track >= 0) {
				this.current_track -= 1;
				play();
			}
		}

	}
}