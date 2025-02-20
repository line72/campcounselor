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
		private bool stopped = true;
		Gst.Element playbin = null;

		public class TrackInfo : GLib.Object {
			public enum TrackStatus {
				STOPPED = 0,
				PLAYING = 1,
				PAUSED = 2
			}
			
			public TrackStatus status;
			public string title;
			public string artist;
			public string album;
			public int64 current_position;
			public int64 duration;
			public string artwork;
			public int current_track;
			public int total_tracks;

			public bool equal(Object other) {
				if (other is TrackInfo) {
					TrackInfo obj2 = other as TrackInfo;
					return (this.status == obj2.status &&
							this.title == obj2.title &&
							this.artist == obj2.artist &&
							this.album == obj2.album &&
							this.current_position == obj2.current_position &&
							this.duration == obj2.duration &&
							this.artwork == obj2.artwork &&
							this.current_track == obj2.current_track &&
							this.total_tracks == obj2.total_tracks);
				}
				return false;
			}
			
		}
		
		private MediaPlayer() {
			playbin = Gst.ElementFactory.make("playbin", "audio_player");

			Gst.Bus bus = playbin.get_bus();
			bus.add_watch(0, (bus1, message) => {
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
					playbin.set_state(Gst.State.NULL);  // Reset pipeline state

					// play next if we can -- If not, we are done with our playlist
					if (!this.next()) {
						// All done
						this.stopped = true;
						GLib.Timeout.add(0, () => {
								MessageBoard.get_instance().publish(MessageBoard.MessageType.PLAYING_STOPPED);
								return false;
							});
					}
					
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

		public static MediaPlayer get_instance() {
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
		}

		
		public void play() {
			if (this.current_track >= 0) {
				BandcampDownloader.Track t = this.tracks.get(this.current_track);
				this.playbin.set_state(Gst.State.NULL);
				this.playbin.set("uri", t.url);
				this.playbin.set_state(Gst.State.PLAYING);

				if (this.stopped) {
					// we have changed state into playing
					GLib.Timeout.add(0, () => {
							MessageBoard.get_instance().publish(MessageBoard.MessageType.PLAYING_STARTED);
							return false;
						});
				}
				
				this.stopped = false;
			}
		}

		public void pause() {
			Gst.State s = get_playback_state();
			if (s == Gst.State.PAUSED) {
				this.playbin.set_state(Gst.State.PLAYING);
				GLib.Timeout.add(0, () => {
						MessageBoard.get_instance().publish(MessageBoard.MessageType.PLAYING_RESUMED);
						return false;
					});
			} else if (s == Gst.State.PLAYING) {
				this.playbin.set_state(Gst.State.PAUSED);
				GLib.Timeout.add(0, () => {
						MessageBoard.get_instance().publish(MessageBoard.MessageType.PLAYING_PAUSED);
						return false;
					});
			}
		}

		public bool next() {
			if (this.current_track < this.tracks.size - 1) {
				this.current_track += 1;
				play();
				return true;
			}
			return false;
		}

		public bool previous() {
			if (this.current_track > 0) {
				this.current_track -= 1;
				play();
				return true;
			}
			return false;
		}

		public TrackInfo get_info() {
			TrackInfo ts = new TrackInfo();
			BandcampDownloader.Track? t = get_track();
			Gst.State state = get_playback_state();

			if (t == null || (this.stopped && state == Gst.State.NULL)) {
				ts.status = TrackInfo.TrackStatus.STOPPED;
				return ts;
			} else {
				ts.artist = t.artist;
				ts.album = t.album;
				ts.title = t.name;
				ts.artwork = this.artwork;
				ts.current_track = this.current_track;
				ts.total_tracks = this.tracks.size;
				if (state == Gst.State.PLAYING) {
					ts.status = TrackInfo.TrackStatus.PLAYING;
				} else if (state == Gst.State.PAUSED) {
					ts.status = TrackInfo.TrackStatus.PAUSED;
				} else {
					ts.status = TrackInfo.TrackStatus.PLAYING;
				}

				playbin.query_position(Gst.Format.TIME, out ts.current_position);
				playbin.query_duration(Gst.Format.TIME, out ts.duration);

				return ts;
			}
		}

		private BandcampDownloader.Track? get_track() {
			if (current_track < tracks.size && current_track >= 0) {
				return tracks.get(current_track);
			}
			return null;
		}

		private Gst.State get_playback_state() {
			Gst.State current_state;
			Gst.State pending_state;
			Gst.StateChangeReturn state_result;

			state_result = playbin.get_state (out current_state, out pending_state, 0);  // 0 means no timeout

			if (state_result == Gst.StateChangeReturn.SUCCESS) {
				return current_state;
			} else {
				return Gst.State.NULL;
			}
		}
		

	}
}