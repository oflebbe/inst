# == Class: inst::profile::hadoop::node::journalnode
class inst::profile::hadoop::node::journalnode (
	$portcheck_package = 'netcat',
	$portcheck_command = '/bin/netcat -z -w 1',
	$portcheck_tries = 24,
	$portcheck_sleep = $::hadoop_bootstrap ? {
		'1' => 60,
		default => 10 },
	$zk,
	) {
	require stdlib

	# make host:port,host:port into host port,host port and split at , into
	# array
	$zookeeper_nodes_space_port = regsubst($zk, ':', ' ', 'G')
	$zookeeper_nodes = split($zookeeper_nodes_space_port, ',')
	$testercommands = prefix($zookeeper_nodes, "${portcheck_command} ")

	# all zookeeper nodes must be up before we can start the journalnodes.
	# Try really hard to find their ports open on bootstrap (60s * 24 == 20
	# Minutes). In production we only tolerate reboot delays (10s * 24 = 4
	# Minutes).
	if !defined(Package[$portcheck_package]) {
		package { $portcheck_package: ensure => present }
	}
	exec{$testercommands:
		tag       => 'checkzookeeper',
		tries     => $portcheck_tries,
		try_sleep => $portcheck_sleep,
		require   => Package[$portcheck_package]
	}

	# a local zookeeper needs to run before we can test it and all checks
	# need to succeed before the journalnode can run
	Service<| title == 'zookeeper-server' |> -> Exec<| tag == 'checkzookeeper' |>
	Exec<| tag == 'checkzookeeper' |> -> Service['hadoop-hdfs-journalnode']
}
