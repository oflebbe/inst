# == Class: inst::profile::hadoop::frontend
class inst::profile::hadoop::frontend (
	$huecert,
	$huekey,
) {
	$hue_apps = hiera('hue::server::hue_apps')
	$hue_packages = $hue_apps ? {
		# The hue metapackage requires all apps
		'all'   => [ 'hue', 'hue-server' ],
		'none'  => [ 'hue-server' ],
		default => concat(prefix($hue_apps, 'hue-'), [ 'hue-server' ])
        }

        file { $huecert:
		tag     => 'hue-ssl-files',
		owner   => 'root',
		group   => 'root',
		mode    => '0444',
		# it's a password file - do not filebucket
		backup  => false,
		source  => "/var/lib/puppet/ssl/certs/${::fqdn}.pem",
		require => Package['hue-server'],
	}
        file { $huekey:
		tag     => 'hue-ssl-files',
		owner   => 'root',
		group   => 'root',
		mode    => '0400',
		# it's a password file - do not filebucket
		backup  => false,
		source  => "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem",
		require => Package['hue-server'],
	}
	Exec<| title == 'init hdfs' |> -> Class['Hadoop-oozie::Server']

	# rdbms support
	file { '/usr/lib/hue/build/env/lib/python2.7/psycopg2':
		ensure  => link,
		target  => '/usr/lib/python2.7/dist-packages/psycopg2',
		require => Package[$hue_packages]
	}

	file { '/usr/lib/hue/build/env/lib/python2.7/psycopg2-2.5.4.egg-info':
		ensure  => link,
		target  => '/usr/lib/python2.7/dist-packages/psycopg2-2.5.4.egg-info',
		require => Package[$hue_packages]
	}

	# django patch
	#$huesitepackages = '/usr/lib/hue/build/env/lib/python2.7/site-packages'
	#$huedjango = "${huesitepackages}/Django-1.6.10-py2.7.egg/django"
	#file { "${huedjango}/db/models/fields/__init__.py":
	#	ensure => present,
	#	source  => 'puppet:///modules/inst/__init__.py',
	#	require => Package[$hue_packages]
	#}
}
