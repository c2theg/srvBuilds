
<?php
$CONFIG = array (
  'instanceid' => 'oc_',
  'passwordsalt' => '',
  'secret' => '',
  'trusted_domains' =>
  array (
    0 => '10.1.1.5',
    1 => 'cloud.site.com'
  ),
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.distributed' => '\\OC\\Memcache\\Memcached',
  'memcached_servers' =>
  array (
    0 =>
    array (
      0 => 'localhost',
      1 => 11211,
    ),
  ),
  'datadirectory' => '/var/www/nextcloud/data',
  'overwrite.cli.url' => 'https://10.1.1.5',
  'dbtype' => '',
  'version' => '',
  'dbname' => '',
  'dbhost' => '',
  'dbport' => '',
  'dbtableprefix' => 'c_',
  'dbuser' => 'Cloud_User',
  'dbpassword' => '',
  'installed' => false,
  'mail_from_address' => 'cloud@site.com',
  'mail_smtpmode' => 'smtp',
  'mail_smtpauthtype' => 'LOGIN',
  'mail_domain' => 'smtp.gmail.com',
  'mail_smtphost' => 'smtp.gmail.net',
  'mail_smtpport' => '25',
  'maintenance' => false,
  'mysql.utf8mb4' => true,
);
