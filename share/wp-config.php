<?php
/**
 * The base configurations of the WordPress.
 *
 * This file has the following configurations: MySQL settings, Table Prefix,
 * Secret Keys, WordPress Language, and ABSPATH. You can find more information
 * by visiting {@link http://codex.wordpress.org/Editing_wp-config.php Editing
 * wp-config.php} Codex page. You can get the MySQL settings from your web host.
 *
 * This file is used by the wp-config.php creation script during the
 * installation. You don't have to use the web site, you can just copy this file
 * to "wp-config.php" and fill in the values.
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', '[% database.name %]');

/** MySQL database username */
define('DB_USER', '[% database.user %]');

/** MySQL database password */
define('DB_PASSWORD', '[% database.password %]');

/** MySQL hostname */
define('DB_HOST', '[% database.host %][% IF database.port %]:[% database.port %][% END %]');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define('AUTH_KEY',         '[% keys.auth %]');
define('SECURE_AUTH_KEY',  '[% keys.secure_auth %]');
define('LOGGED_IN_KEY',    '[% keys.logged_in %]');
define('NONCE_KEY',        '[% keys.nonce %]');
define('AUTH_SALT',        '[% salts.auth %]');
define('SECURE_AUTH_SALT', '[% salts.secure_auth %]');
define('LOGGED_IN_SALT',   '[% salts.logged_in %]');
define('NONCE_SALT',       '[% salts.nonce %]');

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each a unique
 * prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = '[% database.table_prefix ? database.table_prefix : 'wp_' %]';

/**
 * WordPress Localized Language, defaults to English.
 *
 * Change this to localize WordPress. A corresponding MO file for the chosen
 * language must be installed to wp-content/languages. For example, install
 * de_DE.mo to wp-content/languages and set WPLANG to 'de_DE' to enable German
 * language support.
 */
define('WPLANG', '[% wordpress.language %]');

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 */
define('WP_DEBUG', [% wordpress.debug ? 'true' : 'false' %]);

/**
 * Enable the WordPress cache system to allow for installation of caching plugins
 */
define('WP_CACHE', true);

[% IF wordpress.force_ssl -%]
/**
 * Force SSL for administration
 */
define('FORCE_SSL_ADMIN', true);
[% END -%]

[% IF wordpress.multisite AND wordpress.multisite.enabled -%]
/**
 * WordPress network settings
 */
define('WP_ALLOW_MULTISITE', true);
define('MULTISITE', true);
define('SUBDOMAIN_INSTALL', [% wordpress.multisite.subdomain ? 'true' : 'false' %]);
$base = '[% base %]';
define('DOMAIN_CURRENT_SITE', '[% uri.host %]');
define('PATH_CURRENT_SITE', '[% base %]');
define('SITE_ID_CURRENT_SITE', [% wordpress.multisite.site_id %]);
define('BLOG_ID_CURRENT_SITE', [% wordpress.multisite.blog_id %]);
[% END -%]

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
