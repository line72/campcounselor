/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	[GtkTemplate (ui = "/net/line72/campcounselor/ui/editcomment.ui")]
	public class AlbumEditComment : Gtk.Dialog {
		[GtkChild( name = "comment" )]
		public unowned Gtk.TextView comment;

		public AlbumEditComment(Gtk.Window? parent) {
			set_transient_for(parent);
			set_modal(true);
		}
	}
}