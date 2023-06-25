/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	[GtkTemplate (ui = "/net/line72/campcounselor/ui/album.ui")]
	public class AlbumListItem : Gtk.Box {
		[GtkChild( name = "album-band" )]
		public unowned Gtk.Label album_band;
		
		[GtkChild( name = "album-title" )]
		public unowned Gtk.Label album_title;

		[GtkChild( name = "album-uri" )]
		public unowned Gtk.LinkButton album_uri;

		[GtkChild( name = "edit-comment" )]
		public unowned Gtk.Button edit_comment;

		public ulong edit_comment_handler_id;
	}
}