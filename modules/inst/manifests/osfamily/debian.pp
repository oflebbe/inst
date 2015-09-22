# == Class: inst::osfamily::debian
class inst::osfamily::debian {
	# create apt sources.list.d entry resources out of hiera. workaround for old
	# apt module in debian jessie that doesn't support hiera yet. Newer module
	# will do this automatically.
	# Update: Newer module will lookup source via hiera but as
	# priority-first parameter lookup not hash merge. See:
	# https://tickets.puppetlabs.com/browse/MODULES-1672 and
	# https://tickets.puppetlabs.com/browse/MODULES-1507.
	class { 'apt':
		sources => hiera_hash('apt::sources')
	}

	# we can't do this via system::files because that depends on system::packages
	# which in turn we make depend on apt update below -> DEPENCENY CYCLE.
	file { '/etc/apt/apt-repo-keys.asc':
		source => 'puppet:///modules/inst/apt-repo-keys.asc'
	}

	file { '/etc/apt/bigtop-repo-key.asc':
		source => 'puppet:///modules/inst/bigtop-repo-key.asc'
	}
	Class['apt::update'] -> Package<| |>
	
}
