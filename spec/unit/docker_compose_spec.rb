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

describe Specinfra::Backend::DockerCompose do
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

  context '.new' do
    it 'creates an object successfully' do
      subject
    end

    it 'sets Docker URL' do
      expect(Docker).to receive(:url=).once.with(docker_url)
      subject
    end

    it 'loads the docker compose file' do
      expect(DockerCompose).to receive(:load).once.with(compose_file)
        .and_return(compose)
      subject
    end

    context 'without docker_compose_file' do
      before do
        allow_any_instance_of(described_class).to receive(:get_config)
          .with(:docker_compose_file).and_return(nil)
      end

      it 'raises an exception' do
        expect { subject }
          .to raise_error('Please specify docker_compose_file.')
      end
    end

    it 'changes directory' do
      expect(Dir).to receive(:chdir).with('/tmp').once.and_yield
      subject
    end

    it 'starts compose' do
      expect(compose).to receive(:start).once
      subject
    end

    it 'defines the finalizer' do
      expect(ObjectSpace).to receive(:define_finalizer).once
      subject
    end

    it 'does not sleep by default' do
      expect_any_instance_of(described_class).to receive(:sleep).never
      subject
    end

    context 'with docker wait set' do
      let(:docker_wait) { 10 }
      let(:time) { Time.new }
      before do
        allow(Time).to receive(:new).and_return(time)
        allow_any_instance_of(described_class)
          .to receive(:get_config).with(:docker_wait).and_return(docker_wait)
      end

      it 'sleeps' do
        expect_any_instance_of(described_class)
          .to receive(:sleep).once
        subject
      end

      context 'when compose start takes longer than wait' do
        before do
          allow(Time).to receive(:new).and_return(time, time + docker_wait + 1)
        end

        it 'does not sleep by default' do
          expect_any_instance_of(described_class).to receive(:sleep).never
          subject
        end
      end
    end
  end

  context '#run_command' do
    let(:cmd) { 'ls -la' }
    let(:stdout) { %w(ok) }
    let(:stderr) { [] }
    let(:exit_status) { 0 }
    let(:container_name) { 'mysql' }
    let(:container) { double('Docker::Container') }
    let(:compose_container) { double('ComposeContainer', container: container) }
    let(:containers) { { container_name => compose_container } }
    let(:cmd) { 'ls -la' }
    let(:cmd_arg) { ['/bin/sh', '-c', cmd] }
    before do
      allow(subject).to receive(:get_config).with(:docker_compose_container)
        .and_return(container_name)
      allow(compose).to receive(:containers).and_return(containers)
      allow(container).to receive(:exec).with(['/bin/sh', '-c', cmd], {})
        .and_return([stdout, stderr, exit_status])
    end

    it 'runs the command in the container' do
      expect(container).to receive(:exec).once.with(cmd_arg, {})
        .and_return([stdout, stderr, exit_status])
      subject.run_command(cmd)
    end

    it 'calls #rspec_example_metadata' do
      allow(container).to receive(:exec).with(cmd_arg, {})
        .and_return([stdout, stderr, exit_status])
      expect(subject).to receive(:rspec_example_metadata).once
        .with(cmd, stdout.join, stderr.join)
      subject.run_command(cmd)
    end

    context 'without docker_compose_container' do
      before do
        allow(subject).to receive(:get_config).with(:docker_compose_container)
          .and_return(nil)
      end

      it 'returns an error' do
        result = subject.run_command(cmd)
        expect(result.exit_status).to eq(1)
        expect(result.stderr)
          .to match(/Please specify docker_compose_container/)
      end
    end

    context 'with unknown container name' do
      before do
        allow(subject).to receive(:get_config).with(:docker_compose_container)
          .and_return(:unknown)
      end

      it 'returns an error' do
        result = subject.run_command(cmd)
        expect(result.exit_status).to eq(1)
        expect(result.stderr).to match(/Container not found/)
      end
    end

    it 'returns the command result' do
      result = subject.run_command(cmd)
      expect(result).to be_a Specinfra::CommandResult
    end

    it 'returns the exit status' do
      result = subject.run_command(cmd)
      expect(result.success?).to be true
    end

    it 'returns the stdout' do
      result = subject.run_command(cmd)
      expect(result.stdout).to eq(stdout.join)
    end

    it 'returns exit status' do
      result = subject.run_command(cmd)
      expect(result.stderr).to eq('')
    end

    context 'with command errors' do
      let(:error) { 'my error' }
      let(:stderr) { [error] }
      let(:exit_status) { 25 }
      before do
        allow(container).to receive(:exec).with(['/bin/sh', '-c', cmd], {})
          .and_return([stdout, stderr, exit_status])
      end

      it 'returns the error' do
        result = subject.run_command(cmd)
        expect(result.stderr).to eq(error)
      end

      it 'returns the failure' do
        result = subject.run_command(cmd)
        expect(result.failure?).to be true
      end
    end

    context 'with docker gem exceptions when running the command' do
      let(:exception) { Docker::Error::DockerError.new('My Error') }
      before do
        expect(container).to receive(:exec).with(['/bin/sh', '-c', cmd], {})
          .and_raise(exception)
      end

      it 'reraises the exception' do
        expect { subject.run_command(cmd) }.to raise_error(exception)
      end
    end

    context 'with non-docker gem exceptions when running the command' do
      let(:exception) { StandardError.new('EOW') }
      before do
        expect(container).to receive(:exec).with(['/bin/sh', '-c', cmd], {})
          .and_raise(exception)
      end

      it 'does not raise the exception' do
        expect { subject.run_command(cmd) }.to_not raise_error
      end

      it 'stops compose' do
        expect(compose).to receive(:stop).once.with(no_args)
        subject.run_command(cmd)
      end

      it 'deletes compose' do
        expect(compose).to receive(:delete).once.with(no_args)
        subject.run_command(cmd)
      end

      it 'stops the compose' do
        expect(compose).to receive(:stop).once.with(no_args)
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
  end # context #run_command

  context '#rspec_example_metadata' do
    let(:metadata) { {} }
    let(:example) { double('RSpec::Core::Example', metadata: metadata) }
    before { subject.instance_variable_set(:@example, example) }

    it 'sets command on metadata' do
      subject.send(:rspec_example_metadata, 'cmd -l', 'stdout', 'stderr')
      expect(metadata[:command]).to eq 'cmd -l'
    end

    it 'sets stdout on metadata' do
      subject.send(:rspec_example_metadata, 'cmd -l', 'stdout', 'stderr')
      expect(metadata[:stdout]).to eq 'stdout'
    end

    it 'sets stderr on metadata' do
      subject.send(:rspec_example_metadata, 'cmd -l', 'stdout', 'stderr')
      expect(metadata[:stderr]).to eq 'stderr'
    end

    context 'without @example variable' do
      let(:example) { nil }

      it 'does not change @example' do
        subject.send(:rspec_example_metadata, 'cmd -l', 'stdout', 'stderr')
        expect(subject.instance_variable_get(:@example)).to be_nil
      end
    end
  end

  context '#send_file' do
    it 'raises an exception' do
      expect { subject.send_file('from', 'to') }
        .to raise_error(/does not support/)
    end
  end

  context '#finalize' do
    after { subject.send(:finalize) }

    it 'stops compose' do
      expect(compose).to receive(:stop).once.with(no_args)
    end

    it 'deletes compose' do
      expect(compose).to receive(:delete).once.with(no_args)
    end
  end
end
