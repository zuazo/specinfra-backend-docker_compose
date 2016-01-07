# encoding: UTF-8
#
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2016 Xabier de Zuazo
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'
require 'serverspec'

describe Specinfra::Backend::DockerCompose do
  before(:all) do
    path = File.join(File.dirname(__FILE__), '..', 'data')
    set :docker_compose_file, "#{path}/docker-compose.yml"
    set :docker_compose_container, :wordpress
    set :docker_wait, 15
    if lxc_execution_driver?
      set :backend, :docker_compose_lxc
    else
      set :backend, :docker_compose
    end

    # Disable container deletion on Travis, not allowed:
    allow(ObjectSpace).to receive(:define_finalizer) if ENV['TRAVIS_CI']
  end

  describe command('ls -al /') do
    its(:stdout) { should match(/bin/) }
    its(:exit_status) { should eq 0 }
  end

  describe command('apache2 -v') do
    its(:stdout) { should match(/Server +version: +Apache/) }
  end

  describe file('/etc/apache2') do
    it { should exist }
    it { should be_directory }
    it { should be_mode 755 }
  end

  describe file('/usr/sbin/apache2') do
    it { should exist }
    it { should be_file }
    it { should be_mode 755 }
    it { should be_executable }
    it { should be_executable.by_user('root') }
  end

  describe file('/etc/apache2/apache2.conf') do
    it { should exist }
    it { should be_file }
    it { should contain 'DocumentRoot' }
    it do
      should contain('AllowOverride All')
        .from(%r{^<Directory /var/www/>}).to(%r{^</Directory>})
    end
    it { should be_mode 644 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_readable }
    it { should be_readable.by_user('root') }
    it { should be_writable }
    it { should be_writable.by_user('root') }
    its(:size) { should < 641_021 }
  end

  describe group('root') do
    it { should exist }
    it { should have_gid 0 }
  end

  describe interface('eth0') do
    it { should exist }
  end

  describe package('apache2') do
    it { should be_installed }
  end

  describe process('apache2') do
    it { should be_running }
    its(:user) { should eq 'root' }
    its(:args) { should match(/-DFOREGROUND/) }
  end

  describe service('apache2') do
    it { should be_enabled }
    it { should be_running }
  end

  describe user('root') do
    it { should exist }
    it { should belong_to_group 'root' }
    it { should have_uid 0 }
    it { should have_home_directory '/root' }
    it { should have_login_shell '/bin/bash' }
  end
end
