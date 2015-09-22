# == Class: inst::profile::kerberos::server::master
class inst::profile::kerberos::server::master {
	# inter-node-service-dependency checks can cause live-locks. Give it
	# some order: Slave KDC is waiting for its database and might not bring
	# up Hadoop services before that. So push the database before waiting
	# for the Hadoop services. Use resource collector because kprop is only
	# forced when bootstrapping.
	Exec<| title == 'kprop-force' |> -> Exec<| tag == 'checkzookeeper' |>
	Exec<| title == 'kprop-force' |> -> Exec<| tag == 'checkjournalnode' |>
}
