# == Class: inst::profile::hadoop::node::resourcemanagernode
class inst::profile::hadoop::node::resourcemanagernode {

	file { '/etc/hadoop/conf/capacity-scheduler.xml':
		ensure  => present,
		owner   => 'root',
		group   => 'hadoop',
		require => Package['hadoop-yarn-resourcemanager'],
		mode    =>  '0644',
		source  => 'puppet:///modules/inst/capacity-scheduler.xml',
	} ~> Service['hadoop-yarn-resourcemanager']

	Exec<| title == 'init hdfs' |> -> Service['hadoop-yarn-resourcemanager']
	# do we have a history server?
	#Exec<| title == 'init hdfs' |> -> Service['hadoop-yarn-historyserver']
}
