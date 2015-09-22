# == Class: inst::profile::kerberos::server
class inst::profile::kerberos::server ( $pkinit_kdckey, $pkinit_kdccert ) {
	# Normally we would let krb5kdc just read the key directly from
	# puppet's ssl directory. But systemd starts it without
	# CAP_DAC_OVERRIDE (see capabilities(7)). Because of that it can not
	# access anything owned by puppet. So we copy it over to /etc/krb5kdc.
	file { $pkinit_kdccert:
		tag    => 'krb5-pkinit-files',
		owner  => 'root',
		group  => 'root',
		mode   => '0444',
		# it's a password file - do not filebucket
		backup => false,
		source => "/var/lib/puppet/ssl/certs/${::fqdn}.pem",
	}
	file { $pkinit_kdckey:
		tag    => 'krb5-pkinit-files',
		owner  => 'root',
		group  => 'root',
		mode   => '0400',
		# it's a password file - do not filebucket
		backup => false,
		source => "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem",
	}
	File<| tag == 'krb5-pkinit-files' |> ~> Service['krb5-kdc']
}
