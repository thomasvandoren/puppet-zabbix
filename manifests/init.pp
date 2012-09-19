# == Class: zabbix
#
# Install zabbix server from source. The installation steps are from
# http://www.zabbix.com/documentation/2.0/manual/installation/install#from_the_sources.
#
# NOTE: This has only been tested on Ubuntu 12.04 Precise and is
#       mostly intended for development purposes. It was not created
#       for production use, necessarily. Use at your own risk.
#
# === Requires
#
# puppetlabs-mysql
#
# === Examples
#
#   include zabbix
#
# === Authors
#
# Thomas Van Doren
#
# === Copyright
#
# Copyright 2012 Thomas Van Doren, unless otherwise noted
#
class zabbix (
  $zabbix_db_password = 'change me!',
  ) {
  $zabbix_src_dir = '/opt/zabbix-src'
  $packages = ['curl', 'libcurl4-gnutls-dev', 'libmysqlclient-dev', 'make', # build deps
               'apache2', 'libapache2-mod-php5', 'php5', 'php5-gd', 'php5-mysql', # frontend deps
               ]
  $mysql_command = "/usr/bin/mysql --user zabbix --password='${zabbix_db_password}' --database zabbix --batch --raw --skip-column-names --execute"

  # TODO: (thomasvandoren, 2012-09-05) it might be better to simply
  #       declare dependencies on these classes that way the caller can set
  #       them up as they please.
  class { 'mysql': }
  class { 'mysql::server': }

  mysql::db { 'zabbix':
    ensure   => present,
    user     => 'zabbix',
    password => $zabbix_db_password,
    host     => 'localhost',
    grant    => ['all'],
  }
  package { $packages:
    ensure => present,
  }

  group { 'zabbix':
    ensure => present,
  }
  user { 'zabbix':
    ensure  => present,
    gid     => 'zabbix',
    system  => true,
    require => Group['zabbix'],
  }
  File {
    owner   => 'zabbix',
    group   => 'zabbix',
    require => User['zabbix'],
  }
  file { $zabbix_src_dir:
    ensure => directory,
  }
  file { 'zabbix.tar.gz':
    ensure => present,
    path   => "${zabbix_src_dir}/zabbix.tar.gz",
    source => 'puppet:///modules/zabbix/zabbix-2.0.2.tar.gz',
  }
  file { 'frontend-files':
    ensure  => directory,
    recurse => true,
    path    => '/var/www/zabbix',
    owner   => root,
    group   => root,
    source  => "${zabbix_src_dir}/frontends/php",
    require => Package[$packages],
  }
  file { 'frontend-config-dir':
    ensure => directory,
    path   => '/var/www/zabbix/conf',
    owner  => root,
    group  => 'www-data',
    mode   => '0775',
  }
  file { 'frontend-config':
    ensure  => present,
    path    => '/var/www/zabbix/conf/zabbix.conf.php',
    owner   => root,
    group   => 'www-data',
    mode    => '0664',
    content => template('zabbix/zabbix.conf.php.erb'),
  }
  file { 'php.ini':
    ensure  => present,
    path    => '/etc/php5/apache2/php.ini',
    owner   => root,
    group   => root,
    source  => 'puppet:///modules/zabbix/php.ini',
    require => Package[$packages],
    notify  => Service['apache2'],
  }
  file { 'zabbix-init':
    ensure => present,
    path   => '/etc/init.d/zabbix-server',
    owner  => root,
    group  => root,
    mode   => '0755',
    source => 'puppet:///modules/zabbix/zabbix.init',
    notify => Service['zabbix-server'],
  }
  file { 'zabbix_server.conf':
    ensure  => present,
    path    => '/usr/local/etc/zabbix_server.conf',
    owner   => root,
    group   => root,
    content => template('zabbix/zabbix_server.conf.erb'),
    require => Exec['install-zabbix'],
    notify  => Service['zabbix-server'],
  }
  file { ['/var/log/zabbix', '/var/run/zabbix']:
    ensure => directory,
  }
  file { 'zabbix_server.pid':
    ensure => present,
    path   => '/var/run/zabbix/zabbix_server.pid',
  }

  service { 'apache2':
    ensure => running,
    enable => true,
  }
  service { 'zabbix-server':
    ensure  => running,
    enable  => true,
    require => File['/var/log/zabbix'],
  }
  Exec {
    cwd     => $zabbix_src_dir,
    user    => 'zabbix',
    group   => 'zabbix',
    require => Package[$packages],
  }
  exec { 'unpack-zabbix':
    command => '/bin/tar --strip-components 1 --extract --gzip --file zabbix.tar.gz',
    creates => "${zabbix_src_dir}/configure",
    require => File['zabbix.tar.gz'],
  }
  exec { 'configure-zabbix':
    command => '/bin/sh configure --enable-server --with-mysql --with-libcurl',
    creates => "${zabbix_src_dir}/Makefile",
    require => Exec['unpack-zabbix'],
  }
  exec { 'install-zabbix':
    command => '/usr/bin/make install',
    creates => '/usr/local/sbin/zabbix_server',
    user    => root,
    group   => root,
    require => Exec['configure-zabbix'],
  }

  exec { 'database-schema':
    command => "${mysql_command} 'source database/mysql/schema.sql;'",
    onlyif  => "/usr/bin/test $(${mysql_command} 'show tables;' | wc -l) -eq 0",
    require => [ Exec['unpack-zabbix'], Mysql::Db['zabbix'], ],
  }
  exec { 'database-images':
    command => "${mysql_command} 'source database/mysql/images.sql;'",
    onlyif  => "/usr/bin/test $(${mysql_command} 'select count(*) from images;') -eq 0",
    require => Exec['database-schema'],
  }
  exec { 'database-data':
    command => "${mysql_command} 'source database/mysql/data.sql;'",
    onlyif  => "/usr/bin/test $(${mysql_command} 'select count(*) from hosts;') -eq 0",
    require => Exec['database-images'],
  }
}
