/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	public class MessageBoard : GLib.Object {
		private static MessageBoard message_board = null;
		private Gee.HashMap<MessageBoard.MessageType, Gee.HashSet<weak Observer>> observers;

		public enum MessageType {
			PLAYING_STARTED = 0,
			PLAYING_STOPPED
		}

		private MessageBoard() {
			this.observers = new Gee.HashMap<MessageBoard.MessageType, Gee.HashSet<weak Observer>>();
		}

		public static MessageBoard get_instance() {
			if (message_board == null) {
				message_board = new MessageBoard();
			}
			return message_board;
		}

		public void publish(MessageType key) {
			if (observers.has_key(key)) {
				foreach (Observer o in observers[key]) {
					if (o != null) {
						o.notify_of(key);
					}
				}
			}
		}
		
		public void add_observer(MessageType key, Observer observer) {
			if (!observers.has_key(key)) {
				observers.set(key, new Gee.HashSet<weak Observer>());
			}
			observers[key].add(observer);
		}

		public void remove_observer(MessageType key, Observer observer) {
			if (observers.has_key(key)) {
				observers[key].remove(observer);
			}
		}
	}
}