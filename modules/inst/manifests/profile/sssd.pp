# == Class: inst::profile::sssd
class inst::profile::sssd ( $sslcert, $sslkey,
	$host_ticket_cache_ccname,
	$principal = "host/${::fqdn}",
	$keytab = '/etc/krb5.keytab',
	# if we're bootstrapping the master might not be up yet and even if not
	# it might just be rebooting
	$kadmin_try_sleep = $::kerberos_bootstrap ? { '1' => 60, default => 10 },
) {
	# host principal and /etc/krb5.keytab are used by quite a lot of
	# services. So guard against conflicts.
	$ktadd = "${keytab}@${principal}"
	if !defined(Kerberos::Addprinc_keytab_ktadd[$ktadd]) {
		kerberos::addprinc_keytab_ktadd { $ktadd:
			local            => false,
			kadmin_ccache    => $host_ticket_cache_ccname,
			kadmin_tries     => 30,
			kadmin_try_sleep => $kadmin_try_sleep,
			require          => Package['sssd'],
			before           => Service['sssd'],
		}
	}

	file { $sslcert:
		tag    => 'sssd-security-files',
		owner  => 'root',
		group  => 'root',
		mode   => '0444',
		# it's a password file - do not filebucket
		backup => false,
		source => "/var/lib/puppet/ssl/certs/${::fqdn}.pem",
	}

	file { $sslkey:
		tag    => 'sssd-security-files',
		owner  => 'root',
		group  => 'root',
		mode   => '0400',
		# it's a password file - do not filebucket
		backup => false,
		source => "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem",
	}

	Package['sssd'] -> File<| tag == sssd-security-files |> ~> Service['sssd']
}
