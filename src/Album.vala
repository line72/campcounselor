/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

public class CampCounselor.Album : GLib.Object {
	public int id { get; set; }
	public string bandcamp_id { get; set; }
	public string band_id { get; set; }
	public string album { get; set; }
	public string artist { get; set; }
	public string url { get; set; }
	public string thumbnail_url { get; set; }
	public string artwork_url { get; set; }
	public bool purchased { get; set; }
	public string comment { get; set; }
	public int rating { get; set; }
	
	public Album(int id, string bandcamp_id,
				 string band_id, string album,
				 string artist, string url,
				 string thumbnail_url, string artwork_url,
				 bool purchased = false,
				 string comment = "",
				 int rating = -1) {
		this.id = id;
		this.bandcamp_id = bandcamp_id;
		this.band_id = band_id;
		this.album = album;
		this.artist = artist;
		this.url = url;
		this.thumbnail_url = thumbnail_url;
		this.artwork_url = artwork_url;
		this.purchased = purchased;
		this.comment = comment;
		this.rating = rating;
	}
}