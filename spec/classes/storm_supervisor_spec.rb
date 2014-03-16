require 'spec_helper'

describe 'storm::supervisor' do
  context 'supported operating systems' do
    ['RedHat'].each do |osfamily|
      ['RedHat', 'CentOS', 'Amazon', 'Fedora'].each do |operatingsystem|
        let(:facts) {{
          :osfamily        => osfamily,
          :operatingsystem => operatingsystem,
        }}

        describe "storm supervisor with default settings on #{osfamily}" do
          let(:params) {{ }}

          it { should contain_supervisor__service('storm-supervisor').with({
            'ensure'      => 'present',
            'enable'      => true,
            'command'     => '/opt/storm/bin/storm supervisor',
            'directory'   => '/',
            'user'        => 'storm',
            'group'       => 'storm',
            'autorestart' => true,
            'startsecs'   => 10,
            'retries'     => 999,
            'stopsignal'  => 'KILL',
            'stdout_logfile_maxsize' => '20MB',
            'stdout_logfile_keep'    => 5,
            'stderr_logfile_maxsize' => '20MB',
            'stderr_logfile_keep'    => 10,
          })}
        end

      end
    end
  end
end
