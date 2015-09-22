# == Class: inst::profile::hadoop::zookeeper::initnode
class inst::profile::hadoop::zookeeper::initnode (
	$hadoop_security_authentication,
	$zookeeperdir = '/usr/lib/zookeeper',
	$aclnodes = [ '/' ],
	$acls = [ 'sasl:hdfs:cdrwa', 'sasl:yarn:cdrwa', 'sasl:hive:cdrwa' ],
) {
	$zookeepersetaclscmd = "${zookeeperdir}/bin/zkZooKeeperSetAcls.sh"
	$zookeepersetaclsjar = "${zookeeperdir}/lib/ZooKeeperSetAcls.jar"
	file {$zookeepersetaclscmd:
		ensure  => present,
		mode    => '0755',
		source  => 'puppet:///modules/inst/zkZooKeeperSetAcls.sh',
		require => Package['zookeeper'],
	}

	file {$zookeepersetaclsjar:
		ensure  => present,
		mode    => '0644',
		source  => 'puppet:///modules/inst/ZooKeeperSetAcls.jar',
		require => Package['zookeeper'],
	}

	if ($hadoop_security_authentication == 'kerberos') {
		include hadoop::kinit
		Exec['HDFS kinit'] -> Exec['set zookeeper root ACLs']
	}

	require stdlib
	$aclstring = join($acls, ',')
	$aclpaths = join(suffix($aclnodes, " ${aclstring}"), ' ')
	exec { 'set zookeeper root ACLs':
		command => "${zookeepersetaclscmd} -server ${::fqdn} ${aclpaths}",
		path    => ['/bin','/sbin','/usr/bin','/usr/sbin'],
		user    => 'hdfs',
                tries     => 3,
                try_sleep => 10,
		require => [ Service['zookeeper-server'],
			File[$zookeepersetaclscmd],
			File[$zookeepersetaclsjar] ],
	}
}
