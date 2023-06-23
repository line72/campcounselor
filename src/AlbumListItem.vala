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
	}
}