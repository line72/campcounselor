/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	public class DateUtils {
		/**
		 * Parse Bandcamp's dumb dates:
		 * 16 May 2023 20:10:55 GMT
		 */
		public static DateTime? parse(string d) {
			try {
				var r = new Regex("(\\d{2})\\s([A-Za-z]{3})\\s(\\d{4})\\s(\\d{2}):(\\d{2}):(\\d{2})\\sGMT");
				MatchInfo match_info = null;
				if (r.match_full(d, -1, 0, 0, out match_info)) {
					return new DateTime.utc(
						int.parse(match_info.fetch(3)),
						DateUtils.parse_month(match_info.fetch(2)),
						int.parse(match_info.fetch(1)),
						int.parse(match_info.fetch(4)),
						int.parse(match_info.fetch(5)),
						int.parse(match_info.fetch(6))
						);
				} else {
					stdout.printf("Unable to match %s\n", d);
					return null;
				}
			} catch (RegexError e) {
				stdout.printf("Error creating regex %s\n", e.message);
				return null;
			}
		}

		public static int parse_month(string s) {
			switch (s) {
			case "Jan":
				return 1;
			case "Feb":
				return 2;
			case "Mar":
				return 3;
			case "Apr":
				return 4;
			case "May":
				return 5;
			case "Jun":
				return 6;
			case "Jul":
				return 7;
			case "Aug":
				return 8;
			case "Sep":
				return 9;
			case "Oct":
				return 10;
			case "Nov":
				return 11;
			case "Dec":
				return 12;
			default:
				stdout.printf("Invalid month: %s\n", s);
				return 0;
			}
		}
	}
}