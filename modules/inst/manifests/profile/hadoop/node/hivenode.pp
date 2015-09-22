# == Class: inst::profile::hadoop::node::hivenode
class inst::profile::hadoop::node::hivenode (
	$portcheck_package = 'netcat',
	$portcheck_command = '/bin/netcat -z -w 1',
	$portcheck_tries = 24,
	$portcheck_sleep = $::hadoop_bootstrap ? {
		'1' => 60,
		default => 10 },
	$host_ticket_cache_ccname,
	# if we're bootstrapping the master might not be up yet and even if not
	# it might just be rebooting
	$kadmin_try_sleep = $::kerberos_bootstrap ? { '1' => 60, default => 10 },
	$hadoop_security_authentication,
	) {

}
