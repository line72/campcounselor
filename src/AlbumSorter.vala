/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	public class AlbumSorter : Gtk.Sorter {
		public enum AlbumSortType {
			TITLE_ASC,
			TITLE_DESC,
			RATING_ASC,
			RATING_DESC
		}

		private AlbumSortType _sortType;
		public AlbumSortType sortType {
			get { return _sortType; }
			set {
				_sortType = value;
				changed(Gtk.SorterChange.DIFFERENT);
			}
		}
		
		public AlbumSorter(AlbumSortType sortType) {
			Object();

			this.sortType = sortType;
		}

		public override Gtk.Ordering compare(Object? item1, Object? item2) {
			Album a1 = item1 as Album;
			Album a2 = item2 as Album;

			if (sortType == AlbumSortType.TITLE_ASC) {
				if (a1.artist < a2.artist) {
					return Gtk.Ordering.SMALLER;
				} else if (a1.artist > a2.artist) {
					return Gtk.Ordering.LARGER;
				} else {
					return Gtk.Ordering.EQUAL;
				}
			} else if (sortType == AlbumSortType.TITLE_DESC) {
				if (a1.artist < a2.artist) {
					return Gtk.Ordering.LARGER;
				} else if (a1.artist > a2.artist) {
					return Gtk.Ordering.SMALLER;
				} else {
					return Gtk.Ordering.EQUAL;
				}
			} else if (sortType == AlbumSortType.RATING_ASC) {
				if (a1.rating < a2.rating) {
					return Gtk.Ordering.SMALLER;
				} else if (a1.rating > a2.rating) {
					return Gtk.Ordering.LARGER;
				} else {
					return Gtk.Ordering.EQUAL;
				}
			} else if (sortType == AlbumSortType.RATING_DESC) {
				if (a1.rating < a2.rating) {
					return Gtk.Ordering.LARGER;
				} else if (a1.rating > a2.rating) {
					return Gtk.Ordering.SMALLER;
				} else {
					return Gtk.Ordering.EQUAL;
				}
			}

			return Gtk.Ordering.EQUAL;
		}
	}
}