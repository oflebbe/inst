module Puppet::Parser::Functions
	newfunction(:roledef) do |args|
		name = lookupvar("name")
		rolename = name.gsub(/^[^:]+::role/, 'role')

		# rewrite role::our::name to hierapath role/our/name
		setvar('hierapath', rolename.gsub('::', '/'))

		# only try to include parent class if role name still includes
		# any ::
		if rolename.include? "::"
			Puppet::Parser::Functions.function('include')
			parent = name.gsub(/::[^:]+$/, '')
			function_include([ parent ])
		end
	end
end
