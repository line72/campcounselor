/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	[GtkTemplate (ui = "/net/line72/campcounselor/ui/album.ui")]
	public class AlbumListItem : Gtk.Box {
		[GtkChild( name = "album-cover" )]
		public unowned Gtk.Image album_cover;
		
		[GtkChild( name = "album-band" )]
		public unowned Gtk.Label album_band;
		
		[GtkChild( name = "album-title" )]
		public unowned Gtk.Label album_title;

		[GtkChild( name = "album-uri" )]
		public unowned Gtk.LinkButton album_uri;

		[GtkChild( name = "play" )]
		public unowned Gtk.Button play;
		
		[GtkChild( name = "edit-comment" )]
		public unowned Gtk.Button edit_comment;

		[GtkChild( name = "star1" )]
		public unowned Gtk.Image star1;

		[GtkChild( name = "star2" )]
		public unowned Gtk.Image star2;

		[GtkChild( name = "star3" )]
		public unowned Gtk.Image star3;

		[GtkChild( name = "star4" )]
		public unowned Gtk.Image star4;

		[GtkChild( name = "star5" )]
		public unowned Gtk.Image star5;

		public ulong play_handler_id;
		public ulong edit_comment_handler_id;

		public void set_stars(int rating) {
			switch (rating) {
			case 10:
				star5.icon_name = "starred-symbolic";
				star4.icon_name = "starred-symbolic";
				star3.icon_name = "starred-symbolic";
				star2.icon_name = "starred-symbolic";
				star1.icon_name = "starred-symbolic";
				break;
			case 9:
				star5.icon_name = "semi-starred-symbolic";
				star4.icon_name = "starred-symbolic";
				star3.icon_name = "starred-symbolic";
				star2.icon_name = "starred-symbolic";
				star1.icon_name = "starred-symbolic";
				break;
			case 8:
				star5.icon_name = "non-starred-symbolic";
				star4.icon_name = "starred-symbolic";
				star3.icon_name = "starred-symbolic";
				star2.icon_name = "starred-symbolic";
				star1.icon_name = "starred-symbolic";
				break;
			case 7:
				star5.icon_name = "non-starred-symbolic";
				star4.icon_name = "semi-starred-symbolic";
				star3.icon_name = "starred-symbolic";
				star2.icon_name = "starred-symbolic";
				star1.icon_name = "starred-symbolic";
				break;
			case 6:
				star5.icon_name = "non-starred-symbolic";
				star4.icon_name = "non-starred-symbolic";
				star3.icon_name = "starred-symbolic";
				star2.icon_name = "starred-symbolic";
				star1.icon_name = "starred-symbolic";
				break;
			case 5:
				star5.icon_name = "non-starred-symbolic";
				star4.icon_name = "non-starred-symbolic";
				star3.icon_name = "semi-starred-symbolic";
				star2.icon_name = "starred-symbolic";
				star1.icon_name = "starred-symbolic";
				break;
			case 4:
				star5.icon_name = "non-starred-symbolic";
				star4.icon_name = "non-starred-symbolic";
				star3.icon_name = "non-starred-symbolic";
				star2.icon_name = "starred-symbolic";
				star1.icon_name = "starred-symbolic";
				break;
			case 3:
				star5.icon_name = "non-starred-symbolic";
				star4.icon_name = "non-starred-symbolic";
				star3.icon_name = "non-starred-symbolic";
				star2.icon_name = "semi-starred-symbolic";
				star1.icon_name = "starred-symbolic";
				break;
			case 2:
				star5.icon_name = "non-starred-symbolic";
				star4.icon_name = "non-starred-symbolic";
				star3.icon_name = "non-starred-symbolic";
				star2.icon_name = "non-starred-symbolic";
				star1.icon_name = "starred-symbolic";
				break;
			case 1:
				star5.icon_name = "non-starred-symbolic";
				star4.icon_name = "non-starred-symbolic";
				star3.icon_name = "non-starred-symbolic";
				star2.icon_name = "non-starred-symbolic";
				star1.icon_name = "semi-starred-symbolic";
				break;
			default:
				star5.icon_name = "non-starred-symbolic";
				star4.icon_name = "non-starred-symbolic";
				star3.icon_name = "non-starred-symbolic";
				star2.icon_name = "non-starred-symbolic";
				star1.icon_name = "non-starred-symbolic";
				break;
			}
		}
	}
}