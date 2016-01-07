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

describe Specinfra::Backend::DockerComposeLxc do
  let(:docker_url) { 'docker_url' }
  let(:compose_file) { '/tmp/docker-compose.yml' }
  let(:docker_wait) { nil }
  let(:compose) { double('DockerCompose') }
  before do
    # Specinfra::Helper::Configuration value included in RSpec::ExampleGroups
    # instance:
    allow(self).to receive(:docker_url)
    allow(Docker).to receive(:url=).with(any_args)
    allow_any_instance_of(described_class)
      .to receive(:get_config).with(:docker_url).and_return(docker_url)
    allow_any_instance_of(described_class)
      .to receive(:get_config).with(:docker_compose_file)
      .and_return(compose_file)
    allow(DockerCompose).to receive(:load).and_return(compose)
    allow(Dir).to receive(:chdir).and_call_original
    allow(Dir).to receive(:chdir).with('/tmp').and_yield
    allow(compose).to receive(:start)
    allow(compose).to receive(:stop)
    allow(compose).to receive(:delete)
    allow(ObjectSpace).to receive(:define_finalizer)
    allow_any_instance_of(described_class)
      .to receive(:get_config).with(:docker_wait).and_return(docker_wait)
  end

  context '#run_command' do
    let(:cmd) { 'ls -la' }
    let(:stdout) { 'ok' }
    let(:stderr) { '' }
    let(:exit_status) { 0 }
    let(:container_name) { 'mysql' }
    let(:container_id) { 'd2dec2a894fc' }
    let(:container) { double('Docker::Container', id: container_id) }
    let(:compose_container) { double('ComposeContainer', container: container) }
    let(:containers) { { container_name => compose_container } }
    let(:cmd) { 'ls -la' }
    let(:cmd_arg) { ['/bin/sh', '-c', cmd] }
    before do
      allow(subject).to receive(:get_config).with(:docker_compose_container)
        .and_return(container_name)
      allow(compose).to receive(:containers).and_return(containers)
      allow(subject).to receive(:shell_command!)
        .and_return([stdout, stderr, exit_status])
    end

    it 'runs the lxc-attach command' do
      expect(subject).to receive(:shell_command!).once
        .with(['lxc-attach', '-n', container_id, '--', 'sh', '-c', cmd], {})
        .and_return([stdout, stderr, exit_status])
      subject.run_command(cmd)
    end

    it 'reraises LxcAttachError exceptions' do
      error_class = Specinfra::Backend::DockerLxc::LxcAttachError
      allow(subject).to receive(:shell_command!).and_raise(error_class)
      expect { subject.run_command(cmd) }.to raise_error(error_class)
    end

    context 'with non-LxcAttachError exceptions' do
      let(:exception) { StandardError.new('EOW') }
      before do
        allow(subject).to receive(:shell_command!).and_raise(exception)
      end

      it 'stops compose' do
        expect(compose).to receive(:stop).once.with(no_args)
        subject.run_command(cmd)
      end

      it 'deletes compose' do
        expect(compose).to receive(:delete).once.with(no_args)
        subject.run_command(cmd)
      end

      it 'calls #erroneous_result' do
        expect(subject).to receive(:erroneous_result).once.with(cmd, exception)
        subject.run_command(cmd)
      end

      it 'returns #erroneous_result result' do
        expect(subject).to receive(:erroneous_result)
          .and_return('erroneous_result')
        expect(subject.run_command(cmd)).to eq('erroneous_result')
      end
    end

    it 'raises an exception for lxc-attach errors' do
      stderr = 'lxc-attach: Error'
      allow(subject).to receive(:shell_command!).and_return([stdout, stderr, 1])
      expect { subject.run_command(cmd) }
        .to raise_error(
          Specinfra::Backend::DockerLxc::LxcAttachError,
          Regexp.new(Regexp.escape(stderr))
        )
    end

    it 'raises an exception for sudo errors' do
      stderr = 'sudo: Error'
      allow(subject).to receive(:shell_command!).and_return([stdout, stderr, 1])
      expect { subject.run_command(cmd) }
        .to raise_error(
          Specinfra::Backend::DockerLxc::LxcAttachError,
          Regexp.new(Regexp.escape(stderr))
        )
    end

    it 'does not raise any error for normal shell errors' do
      stderr = 'myapp: Error'
      allow(subject).to receive(:shell_command!).and_return([stdout, stderr, 1])
      expect { subject.run_command(cmd) }.to_not raise_error
    end
  end # context #run_command!
end
