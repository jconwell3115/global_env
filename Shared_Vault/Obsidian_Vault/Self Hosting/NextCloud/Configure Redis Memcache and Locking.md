---
title: Configure Redis Memcache and Locking
tags:
  - Self-Hosting
  - NextCloud
  - Podman
  - podman-compose
created: 2025-12-03
published:
status: draft
---
1. Nano isn't installed in the Nextcloud container by default
```bash
# Inside the container (you're already in: root@ae6edd369331:/var/www/html#)
apt-get update && apt-get install -y nano
```

2. Backup config/config.php 
```bash
cp -pr config/config.php config/config.php.bak
```

3. Open the config/cofnig.php file for editing:
```bash
nano config/config.php
```

4. Configure Redis for memcache and file locking:
```php
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.distributed' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' => 
  array (
    'host' => 'nextcloud_redis',
    'port' => 6379,
    'password' => '',
    'dbindex' => 0,
  )
```

5. Whole file show for clarity
```php
<?php
$CONFIG = array (
  'htaccess.RewriteBase' => '/',
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.distributed' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' => 
  array (
    'host' => 'nextcloud_redis',
    'port' => 6379,
    'password' => '',
    'dbindex' => 0,
  ),
  'apps_paths' =>
  array (
    0 =>
    array (
      'path' => '/var/www/html/apps',
      'url' => '/apps',
      'writable' => false,
    ),
    1 =>
    array (
      'path' => '/var/www/html/custom_apps',
      'url' => '/custom_apps',
      'writable' => true,
    ),
  ),
  'upgrade.disable-web' => true,
  'passwordsalt' => 'aV1egjinEjJUdh1E2C+DVYJmtMBZB9',
  'secret' => 'aIJMjMDbeY6wpZMA1dlwShdaLmUogHYz+Tyatz0xJ8P4tML1',
  'trusted_domains' =>
  array (
    0 => 'localhost',
    1 => 'localhost:8080',
    2 => '192.168.0. 100:8080',
    3 => 'nextcloud.rhlabs.org',
  ),
  'datadirectory' => '/var/www/html/data',
  'dbtype' => 'mysql',
  'version' => '32.0. 2.2',
  'overwrite.cli.url' => 'https://nextcloud.rhlabs.org',
  'dbname' => 'nextcloud',
  'dbhost' => 'db',
  'dbtableprefix' => 'oc_',
  'mysql. utf8mb4' => true,
  'dbuser' => 'ncuser',
  'dbpassword' => 'nextcloudpass',
  'installed' => true,
  'instanceid' => 'ocqvk4uwtw3q',
  'overwritehost' => 'nextcloud.rhlabs.org',
  'overwriteprotocol' => 'https',
  'trusted_proxies' =>
  array (
    0 => '127.0.0.1',
  ),
);
```


