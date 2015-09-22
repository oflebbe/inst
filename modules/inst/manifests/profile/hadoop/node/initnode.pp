# == Class: inst::profile::hadoop::node::initnode
class inst::profile::hadoop::node::initnode (
	$init_hdfs_check_path = '/apps/tez/lib',
	$hadoop_security_authentication,
	) {
	if ($hadoop_security_authentication == 'kerberos') {
		include hadoop::kinit
		Exec['HDFS kinit'] -> Exec['init hdfs']
	}

	# patch file
        file {'/usr/lib/hadoop/libexec/init-hcfs.json':
	     ensure => present,
	     mode => 0755,
	     source  => 'puppet:///modules/inst/init-hcfs.json',
      	     require => Package['hadoop-hdfs'],
	}

	exec { 'init hdfs':
		path    => ['/bin','/sbin','/usr/bin','/usr/sbin'],
		command => 'bash -e /usr/lib/hadoop/libexec/init-hdfs.sh',
		require =>  [ File['/usr/lib/hadoop/libexec/init-hcfs.json'], Package['tez'], Package['python-snakebite']],
		unless  => "su - hdfs -c 'snakebite stat ${init_hdfs_check_path}'",
		timeout => 60,
	}
}
