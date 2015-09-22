# == Class: inst::profile::ldap::server
class inst::profile::ldap::server (
	$slapdcert,
	$slapdkey,
	$host_ticket_cache_ccname,
	$principal = "ldap/${::fqdn}",
	$krb5_keytab,
	# if we're bootstrapping the master might not be up yet and even if not
	# it might just be rebooting
	$kadmin_try_sleep = $::kerberos_bootstrap ? { '1' => 60, default => 10 },
) {
	# slapd can't read its keys directly from puppet's varlibdir because it
	# drops privileges before trying.
	file { $slapdcert:
		tag     => 'slapd-ssl-files',
		owner   => 'root',
		group   => 'root',
		mode    => '0444',
		# it's a password file - do not filebucket
		backup  => false,
		source  => "/var/lib/puppet/ssl/certs/${::fqdn}.pem",
		require => Package['slapd'],
	}
	file { $slapdkey:
		tag     => 'slapd-ssl-files',
		owner   => 'openldap',
		group   => 'root',
		mode    => '0400',
		# it's a password file - do not filebucket
		backup  => false,
		source  => "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem",
		require => Package['slapd'],
	}
	File<| tag == 'slapd-ssl-files' |> ~> Service['slapd']
	kerberos::addprinc_keytab_ktadd { "${krb5_keytab}@${principal}":
		local            => false,
		keytab_owner     => 'openldap',
		kadmin_ccache    => $host_ticket_cache_ccname,
		#if we're bootstrapping the master might not be up yet and even if not
		# it might just be rebooting
		kadmin_tries     => 30,
		kadmin_try_sleep => $kadmin_try_sleep,
		require          => [ Package['slapd'] ],
	}
	file { '/etc/ldap/sasl2/slapd.conf':
		tag     => 'slapd-sasl-config',
		owner   => 'openldap',
		group   => 'root',
		mode    => '0644',
		content => "mech_list: external gssapi plain\npwcheck_method: saslauthd\n",
		require => Package['slapd'],
	}
	exec {'sasl openldap membership':
		unless  => '/usr/bin/getent group sasl | /bin/grep -q openldap',
		command => '/usr/sbin/usermod -a -G sasl openldap',
		require => Package['slapd'],
	}
}
