# == Class: inst::profile::nagios::client::hdfs
class inst::profile::nagios::client::hdfs (
	$host_ticket_cache_ccname,
	$principal = "nagios/${::fqdn}",
	$keytab = '/etc/nagios.keytab',
	# if we're bootstrapping the master might not be up yet and even if not
	# it might just be rebooting
	$kadmin_try_sleep = $::kerberos_bootstrap ? { '1' => 60, default => 10 },
) {
	kerberos::addprinc_keytab_ktadd { "${keytab}@${principal}":
		local            => false,
		keytab_owner     => 'nagios',
		kadmin_ccache    => $host_ticket_cache_ccname,
		kadmin_tries     => 30,
		kadmin_try_sleep => $kadmin_try_sleep,
		# creates user nagios
		require          => [ Package['nagios-nrpe-server'] ],
	}
}
