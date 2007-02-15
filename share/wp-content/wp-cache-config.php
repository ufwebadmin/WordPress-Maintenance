<?php
$cache_enabled = [% wordpress.wp_cache.enabled ? 'true' : 'false' %];
$cache_max_time = [% wordpress.wp_cache.ttl || 3600 %]; // seconds
$use_flock = true;
$cache_path = ABSPATH . 'wp-content/wp-cache/';
$file_prefix = 'wp-cache-';
$known_headers = array("Last-Modified", "Expires", "Content-Type", "X-Pingback", "ETag", "Cache-Control", "Pragma");

// Array of files that have 'wp-' but should still be cached
$cache_acceptable_files = array('[% wordpress.wp_cache.acceptable_files.join("', '") %]');

$cache_rejected_uri = array('[% wordpress.wp_cache.rejected_uris.join("', '") %]');
$cache_rejected_user_agent = array ( 0 => 'bot', 1 => 'ia_archive', 2 => 'slurp', 3 => 'crawl', 4 => 'spider');

// Just modify it if you have conflicts with semaphores
$sem_id = 5419;

if (!class_exists('CacheMeta')) {
	class CacheMeta {
		var $dynamic = false;
		var $headers = array();
		var $uri = '';
		var $post = 0;
	}
}

if ( '/' != substr($cache_path, -1)) {
	$cache_path .= '/';
}
?>
