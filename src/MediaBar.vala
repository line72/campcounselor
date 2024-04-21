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
		
	}
}
