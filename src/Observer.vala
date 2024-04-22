/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	public interface Observer : GLib.Object {
		public abstract void notify_of(MessageBoard.MessageType message);
	}
}