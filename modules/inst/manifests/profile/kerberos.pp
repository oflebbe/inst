# == Class: inst::profile::kerberos
class inst::profile::kerberos ( $pkinit_cacert ) {
	# Normal users are not allowed to access puppet's ssl directory. So
	# copy the CA certificate over to /etc/puppet.
	file {$pkinit_cacert:
		tag    => 'krb5-pkinit-files',
		owner  => 'root',
		group  => 'root',
		mode   => '0444',
		# it's a password file - do not filebucket
		backup => false,
		source => '/var/lib/puppet/ssl/certs/ca.pem',
	}
}
