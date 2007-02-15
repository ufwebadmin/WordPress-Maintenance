<?php
// ** MySQL settings ** //
define('DB_NAME', '[% database.name %]');    // The name of the database
define('DB_USER', '[% database.username %]');     // Your MySQL username
define('DB_PASSWORD', '[% database.password %]'); // ...and password
define('DB_HOST', '[% database.hostname %][% IF database.port %]:[% database.port %][% END %]');    // 99% chance you won't need to change this value

// You can have multiple installations in one database if you give each a unique prefix
$table_prefix  = 'wp_';   // Only numbers, letters, and underscores please!

// Change this to localize WordPress.  A corresponding MO file for the
// chosen language must be installed to wp-includes/languages.
// For example, install de.mo to wp-includes/languages and set WPLANG to 'de'
// to enable German language support.
define ('WPLANG', '');

// For the wp-cache plugin
define('WP_CACHE', true);

/* That's all, stop editing! Happy blogging. */

define('ABSPATH', dirname(__FILE__).'/');
require_once(ABSPATH.'wp-settings.php');
?>
