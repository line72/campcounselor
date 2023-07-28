[CCode (lower_case_cprefix = "", cheader_filename = "config.h")]
namespace Config {
	[CCode (cname = "APP_ID")]
	public const string APP_ID;
	
	/* Package information */
	[CCode (cname = "PACKAGE_NAME")]
	public const string PACKAGE_NAME;

	[CCode (cname = "PACKAGE_STRING")]
	public const string PACKAGE_STRING;

	[CCode (cname = "PACKAGE_VERSION")]
	public const string PACKAGE_VERSION;

	[CCode (cname = "SOURCE_DIR")]
	public const string SOURCE_DIR;
	
	/* Gettext package */
	public const string GETTEXT_PACKAGE;
	
	/* Configured paths - these variables are not present in config.h, they are
	 * passed to underlying C code as cmd line macros. */
	public const string LOCALEDIR; /* /usr/local/share/locale */
	public const string LIBEXECDIR;
	
	[CCode (cname = "DATADIR")]
	public const string DATADIR;
}
