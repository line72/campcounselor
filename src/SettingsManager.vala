/*
 * (c) 2023 Marcus Dillavou <line72@line72.net>
 * License: GPLv3 or Later
 */

namespace CampCounselor {
	class SettingsManager : GLib.Object {
		private static SettingsManager instance = null;
		public Settings settings = null;
		public Settings db_settings = null;

		public static SettingsManager get_instance() throws GLib.Error {
			if (instance == null) {
				instance = new SettingsManager();
			}

			return instance;
		}


		public int filterby_to_enum(string s) {
			if (s == "all") {
				return 0;
			} else if (s == "wishlist") {
				return 1;
			} else if (s == "purchased") {
				return 2;
			}
			return 0;
		}

		public string enum_to_filterby(int e) {
			switch (e) {
			case 0:
				return "all";
			case 1:
				return "wishlist";
			case 2:
				return "purchased";
			default:
				return "all";
			}
		}

		public string enum_to_sortby(int e) {
			switch (e) {
			case 0:
				return "title_asc";
			case 1:
				return "title_desc";
			case 2:
				return "rating_asc";
			case 3:
				return "rating_desc";
			case 4:
				return "created_asc";
			case 5:
				return "created_desc";
			case 6:
				return "updated_asc";
			case 7:
				return "updated_desc";
			}
			return "title_asc";
		}

		
		private SettingsManager() throws GLib.Error {
			this.settings = get_settings(Config.APP_ID);
			this.db_settings = get_settings(@"$(Config.APP_ID).postgresql");
		}

		private Settings? get_settings(string id) throws GLib.Error {
			var s = get_settings_from_system(id) ??
				(get_settings_from(Config.DATADIR + "/glib-2.0/schemas", id) ??
				 get_settings_from(Config.SOURCE_DIR + "/build/data", id));
			if (s == null) {
				throw new GLib.Error(823424, 0, @"Unable to load settings for $(id)");
			}

			return s;
		}
			
		private Settings? get_settings_from_system(string id) {
			var sss = SettingsSchemaSource.get_default ();
			if (sss == null) {
				stdout.printf("Error loading settings schema\n");
				return null;
			}
			stdout.printf(id + "\n");
			var schema = sss.lookup(id, true);
			if (schema == null) {
				stdout.printf("Schema is null\n");
				return null;
			}
			return new Settings.full(schema, null, null);
		}

		private Settings? get_settings_from(string directory, string id) {
			stdout.printf("get_settings_from %s\n", directory);
			try {
				var sss = new SettingsSchemaSource.from_directory (directory, null, false);
				var schema = sss.lookup (id, false);
				if (schema == null) {
					stdout.printf ("The schema specified was not found on the custom location");
					return null;
				}

				return new Settings.full (schema, null, null);
			} catch (Error e) {
				stdout.printf ("An error ocurred: directory not found, corrupted files found, empty files...");
				return null;
			}
		}
	}
}