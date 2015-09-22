# == Class: inst::profile::hadoop::node::namenode
class inst::profile::hadoop::node::namenode (
	$portcheck_package = 'netcat',
	$portcheck_command = '/bin/netcat -z -w 1',
	$portcheck_tries = 24,
	$portcheck_sleep = $::hadoop_bootstrap ? {
		'1' => 60,
		default => 10 },
	$shared_edits_dir,
	) {
	require stdlib

	# remove leading qjournal://, trailing path, make host:port;host:port
	# into host port;host port and split at ;
	$shared_edits_dir_noqjournal = regsubst($shared_edits_dir, '.*://', '')
	$shared_edits_dir_nopath = regsubst($shared_edits_dir_noqjournal, '/.*', '')
	$journalnodes_space_port = regsubst($shared_edits_dir_nopath, ':', ' ', 'G')
	$journalnodes = split($journalnodes_space_port, ';')
	$testercommands = prefix($journalnodes, "${portcheck_command} ")

	# all journalnodes must be up before we can start the namenodes. Try
	# really hard to find their ports open on bootstrap (60s * 24 == 24
	# Minutes). In production we only tolerate reboot delays (10s * 24 = 4
	# Minutes).
	if !defined(Package[$portcheck_package]) {
		package { $portcheck_package: ensure => present }
	}
	exec{$testercommands:
		tag       => 'checkjournalnode',
		tries     => $portcheck_tries,
		try_sleep => $portcheck_sleep,
		require   => Package[$portcheck_package]
	}

	# a local journalnode needs to run before we can test it and all checks
	# need to succeed before we can start the namenode. Since formatting is a
	# requisite for that on all namenodes (being a -bootstrapStandby on all
	# but the first), we make that dependant on our checks.
	Service<| title == 'hadoop-hdfs-journalnode' |> ->
		Exec<| tag == 'checkjournalnode' |> ->
		Exec<| tag == 'namenode-format' |>

	file{'/etc/systemd/system/hadoop-hdfs-zkfc.service':
	   ensure=>present,
           source  => 'puppet:///modules/inst/hadoop-hdfs-zkfc.service',
        }
        File['/etc/systemd/system/hadoop-hdfs-zkfc.service'] -> Service['hadoop-hdfs-zkfc']

}
