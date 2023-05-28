/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

public class CampCounselor.Album : GLib.Object {
	public string id;
	public string band_id;
	public string album;
	public string artist;
	public string url;
	public string thumbnail_url;
	public string artwork_url;
	
	public Album(string id, string band_id, string album,
				 string artist, string url,
				 string thumbnail_url, string artwork_url) {
		this.id = id;
		this.band_id = band_id;
		this.album = album;
		this.artist = artist;
		this.url = url;
		this.thumbnail_url = thumbnail_url;
		this.artwork_url = artwork_url;
	}
}