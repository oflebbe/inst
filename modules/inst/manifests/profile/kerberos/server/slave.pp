# == Class: inst::profile::kerberos::server::slave
class inst::profile::kerberos::server::slave {

      file { '/lib/systemd/system/krb5-kpropd.service':
	        tag    => 'kprop-unit',
		owner  => 'root',
		group  => 'root',
		mode   => '0644',
		source => "puppet:///modules/inst/krb5-kpropd.service",
	}
	file { '/etc/init.d/krb5-kpropd':
	        tag    => 'kprop-unit',
		owner  => 'root',
		group  => 'root',
		mode   => '0755',
		source => "puppet:///modules/inst/krb5-kpropd.init",
	}
	exec { '/bin/systemctl enable krb5-kpropd':
        }
		
	File<| tag == 'kprop-unit' |> -> Exec['/bin/systemctl enable krb5-kpropd'] -> Service['kpropd']
}
