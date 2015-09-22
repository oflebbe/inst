# == Class: inst

class inst {
	# will be n/a if lsb_release command is not installed
	if $::lsbdistcodename == 'n/a' {
		# is jessie/sid for Debian jessie
		$osreleasecomponents = split($::operatingsystemrelease, '/')
		$distcodename = $osreleasecomponents[0]
	} else {
		$distcodename = $::lsbdistcodename
	}

	# intialise hiera search hierarchy via role classes
	hiera_include('inst::roles', '')
}
