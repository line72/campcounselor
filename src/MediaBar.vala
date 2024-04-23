/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	[GtkTemplate (ui = "/net/line72/campcounselor/ui/mediabar.ui")]
	public class MediaBar : Gtk.Box, Observer {
		[GtkChild( name = "action-bar") ]
		public unowned Gtk.ActionBar action_bar;
		
		[GtkChild( name = "cover-art" )]
		public unowned Gtk.Image cover_art;

		[GtkChild( name = "play-pause-button" )]
		public unowned Gtk.Button play_btn;

		[GtkChild( name = "play-pause-icon" )]
		public unowned Gtk.Image play_icon;

		[GtkChild( name = "song-title" )]
		public unowned Gtk.Label song_title;

		[GtkChild( name = "song-album" )]
		public unowned Gtk.Label song_album;

		[GtkChild( name = "current-time" )]
		public unowned Gtk.Label current_time;

		[GtkChild( name = "duration" )]
		public unowned Gtk.Label duration;

		[GtkChild( name = "song-progress-bar" )]
		public unowned Gtk.ProgressBar progress_bar;
		
		[GtkChild( name = "skip-back-button" )]
		public unowned Gtk.Button skip_back;

		[GtkChild( name = "skip-next-button" )]
		public unowned Gtk.Button skip_next;

		private bool needs_stop = false;
		
		construct {
			play_btn.clicked.connect(() => {
					MediaPlayer mp = MediaPlayer.get_instance();
					mp.pause();
				});
			skip_back.clicked.connect(() => {
					MediaPlayer mp = MediaPlayer.get_instance();
					mp.previous();
				});
			skip_next.clicked.connect(() => {
					MediaPlayer mp = MediaPlayer.get_instance();
					mp.next();
				});

			// start monitoring the messageboard
			MessageBoard.get_instance().add_observer(MessageBoard.MessageType.PLAYING_STARTED, this);
			MessageBoard.get_instance().add_observer(MessageBoard.MessageType.PLAYING_STOPPED, this);
		}

		public void notify_of(MessageBoard.MessageType message) {
			switch (message) {
			case MessageBoard.MessageType.PLAYING_STARTED:
				reveal();
				break;
			case MessageBoard.MessageType.PLAYING_STOPPED:
				unreveal();
				break;
			default:
				break;
			}
		}
		
		private void reveal() {
			this.action_bar.revealed = true;

			// start a timer to upload
			GLib.Timeout.add(250, () => {
					return update();
				});
		}

		private void unreveal() {
			this.action_bar.revealed = false;
			this.needs_stop = true;
		}

		public bool update() {
			MediaPlayer mp = MediaPlayer.get_instance();
			MediaPlayer.TrackInfo t = mp.get_info();

			if (t.status == MediaPlayer.TrackInfo.TrackStatus.STOPPED) {
				this.song_title.set_text("");
			} else {
				var f = (double)t.current_position / t.duration;
				this.progress_bar.fraction = f;

				if (t.status == MediaPlayer.TrackInfo.TrackStatus.PAUSED) {
					play_icon.icon_name = "media-playback-start";
				} else {
					play_icon.icon_name = "media-playback-pause";
				}

				if (t.current_track <= 0) {
					skip_back.sensitive = false;
				} else {
					skip_back.sensitive = true;
				}

				if (t.current_track >= t.total_tracks - 1) {
					skip_next.sensitive = false;
				} else {
					skip_next.sensitive = true;
				}

				if (cover_art.file != t.artwork) {
					cover_art.file = t.artwork;
				}
				
				this.song_title.set_text(t.title);
				this.song_album.set_text(@"$(t.artist) - $(t.album)");
				this.current_time.set_text(format_time(t.current_position));
				this.duration.set_text(format_time(t.duration));
			}

			if (this.needs_stop) {
				this.needs_stop = false;
				return false; // stop updating
			}
			
			return true;
		}

		private string format_time (int64 ns) {
			int64 total_seconds = ns / 1000000000;
			int64 minutes = total_seconds / 60;
			int64 seconds = total_seconds % 60;

			return "%02lld:%02lld".printf (minutes, seconds);
		}
	}
}
