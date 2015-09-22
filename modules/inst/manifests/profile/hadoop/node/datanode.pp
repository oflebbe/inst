# == Class: inst::profile::hadoop::node::datanode
class inst::profile::hadoop::node::datanode {
	# configure and start ourselves before trying to init HDFS
	Service['hadoop-hdfs-datanode'] -> Exec<| title == 'init hdfs' |>
	Service['hadoop-yarn-nodemanager'] -> Exec<| title == 'init hdfs' |>
}
