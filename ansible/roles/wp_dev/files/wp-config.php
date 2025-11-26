<?php
/** WordPress base configuration */

// ** Database settings — since this is a static file, all values are hardcoded ** //
define( 'DB_NAME', 'wp_dev' );
define( 'DB_USER', 'wp_user' );
define( 'DB_PASSWORD', '4%VnX*d^l1a9R9gwWx&L!GQfQ@1DNd4B' );
define( 'DB_HOST', 'localhost' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

// ** Table prefix ** //
$table_prefix = 'wp_';

// ** Debug mode ** //
define( 'WP_DEBUG', false );

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
