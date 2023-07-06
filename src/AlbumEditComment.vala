/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	[GtkTemplate (ui = "/net/line72/campcounselor/ui/editcomment.ui")]
	public class AlbumEditComment : Gtk.Dialog {
		[GtkChild( name = "comment" )]
		public unowned Gtk.TextView comment;

		[GtkChild( name = "artist_lbl" )]
		public unowned Adw.ActionRow artist;
		
		[GtkChild( name = "album_lbl" )]
		public unowned Adw.ActionRow album;
		
		[GtkChild( name = "rating_lbl" )]
		public unowned Adw.ActionRow rating;
		
		public AlbumEditComment(Album album, Gtk.Window? parent) {
			set_transient_for(parent);
			set_modal(true);

			var buffer = this.comment.get_buffer();
			buffer.set_text(album.comment, -1);

			this.artist.subtitle = album.artist;
			this.album.subtitle = album.album;
			this.rating.subtitle = album.rating.to_string();
		}
	}
}