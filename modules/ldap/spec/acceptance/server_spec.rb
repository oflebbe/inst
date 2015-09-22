require 'spec_helper_acceptance'

describe 'ldap::server class' do

  context 'required parameters' do
    it 'should work idempotently with no errors' do
      pp = <<-EOS
        class { 'ldap::server':
          suffix => 'dc=example,dc=com',
          rootdn => 'cn=admin,dc=example,dc=com',
          rootpw => 'llama123',
        }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end

    describe package('slapd') do
      it { is_expected.to be_installed }
    end

    describe service('slapd') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end
  end
end
