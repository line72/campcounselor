/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	[GtkTemplate (ui = "/net/line72/campcounselor/ui/mediabar.ui")]
	public class MediaBar : Gtk.Box {
		[GtkChild( name = "action-bar") ]
		public unowned Gtk.ActionBar action_bar;
		
		[GtkChild( name = "cover-art" )]
		public unowned Gtk.Image cover_art;

		[GtkChild( name = "play-pause-button" )]
		public unowned Gtk.Button play_btn;

		[GtkChild( name = "play-pause-icon" )]
		public unowned Gtk.Image play_icon;

		[GtkChild( name = "song-status" )]
		public unowned Gtk.Label song_title;

		[GtkChild( name = "song-progress-bar" )]
		public unowned Gtk.ProgressBar progress_bar;
		
		[GtkChild( name = "skip-back-button" )]
		public unowned Gtk.Button skip_back;

		[GtkChild( name = "skip-next-button" )]
		public unowned Gtk.Button skip_next;


		
		construct {
			play_btn.clicked.connect(() => {
					stdout.printf("play_btn clicked\n");
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
		}
		
		public void reveal() {
			this.action_bar.revealed = true;

			// start a timer to upload
			GLib.Timeout.add(250, () => {
					var r = update();
					if (!r) {
						this.action_bar.revealed = false;
					}
					return r;
				});
		}

		public bool update() {
			MediaPlayer mp = MediaPlayer.get_instance();
			MediaPlayer.TrackInfo t = mp.get_info();

			if (t.status == MediaPlayer.TrackInfo.TrackStatus.STOPPED) {
				this.song_title.set_text("");
				return false;
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
				
				this.song_title.set_text(@"$(t.title) $(format_time(t.current_position)) / $(format_time(t.duration))");
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
