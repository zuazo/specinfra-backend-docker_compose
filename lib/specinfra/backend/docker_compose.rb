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

require 'docker-compose'
require 'specinfra/backend/exec'

# Command Execution Framework for Serverspec, Itamae and so on.
module Specinfra
  # Specinfra backend types.
  module Backend
    # Specinfra and Serverspec backend for Docker Compose.
    class DockerCompose < Exec
      # Constructs a Docker Compose Specinfra Backend.
      #
      # @param config [Hash] Configuration options.
      # @option config [String] docker_compose_file: Docker Compose
      #   configuration file path (**required**).
      # @option config [String] docker_compose_container: The name of the
      #   container you want to test (**required**). Only one can be tested.
      # @option config [Fixnum] docker_wait: Seconds to wait for containers to
      #   start (i.e., time to sleep before running the tests)
      #   (**recommended**).
      # @api public
      def initialize(config = {})
        super

        ::Docker.url = get_config(:docker_url)

        file = get_config(:docker_compose_file)
        fail 'Please specify docker_compose_file.' unless file

        @compose = ::DockerCompose.load(file)
        ObjectSpace.define_finalizer(self, proc { finalize })
        Dir.chdir(::File.dirname(file)) { do_start }
      end

      # Runs a Specinfra command.
      #
      # @param cmd [String] The command to run.
      # @param opts [Hash] Options to pass to {Docker::Container#exec}.
      # @return nil
      # @api public
      def run_command(cmd, opts = {})
        cmd = build_command(cmd)
        cmd = add_pre_command(cmd)
        docker_compose_run!(cmd, opts)
      end

      # Builds a command.
      #
      # Does nothing.
      #
      # @param cmd [String] The command to run.
      # @return [String] The command.
      # @api public
      def build_command(cmd)
        cmd
      end

      # Adds a prefix or previous instruction to the command.
      #
      # Does nothing.
      #
      # @param cmd [String] The command to run.
      # @return [String] The command.
      # @api public
      def add_pre_command(cmd)
        cmd
      end

      # Sends a file.
      #
      # @note Not implemented yet.
      # @param _from [String] The file origin.
      # @param _to [String] The file destination.
      # @raise [RuntimeError] Always raises an error.
      # @return nil
      # @api public
      def send_file(_from, _to)
        fail 'docker_compose does not support send_file'
      end

      protected

      # Returns the selected Docker Container name.
      #
      # Gets the container name to return from the `:docker_compose_container`
      # Specinfra configuration option.
      #
      # @return [String] The container name.
      # @api private
      def docker_compose_container
        get_config(:docker_compose_container).to_s
      end

      # Returns the selected Docker Container object.
      #
      # Gets the container name to return from the `:docker_compose_container`
      # Specinfra configuration option.
      #
      # @return [Docker::Container] The container object.
      # @raise [RuntimeError] When the container is not selected or the
      #   selected container is not found.
      # @api private
      def container
        if docker_compose_container.empty?
          fail 'Please specify docker_compose_container.'
        end
        compose_container = @compose.containers[docker_compose_container]
        if compose_container.nil?
          fail "Container not found: #{docker_compose_container.inspect}"
        end
        compose_container.container
      end

      # Stops the containers started by Docker Compose and deletes them.
      #
      # Called automatically when this object is destroyed.
      #
      # @return nil
      # @api private
      def finalize
        @compose.stop
        @compose.delete
      end

      # Parses a rescued exception and returns the command result.
      #
      # @param cmd [Array<String>, String] The command.
      # @param exception [Exception] The exception to parse.
      # @return [Specinfra::CommandResult] The generated result object.
      # @api public
      def erroneous_result(cmd, exception)
        stdout = nil
        stderr = ([exception.message] + exception.backtrace).join("\n")
        status = 1
        rspec_example_metadata(cmd, stdout, stderr)
        CommandResult.new(stdout: stdout, stderr: stderr, exit_status: status)
      end

      # Updates RSpec metadata used by Serverspec.
      #
      # @param cmd [Array<String>, String] The command.
      # @param stdout [String, nil] The *stdout* output.
      # @param stderr [String, nil] The *stderr* output.
      # @return nil
      # @api public
      def rspec_example_metadata(cmd, stdout, stderr)
        return unless @example
        @example.metadata[:command] = cmd
        @example.metadata[:stdout] = stdout
        @example.metadata[:stderr] = stderr
      end

      # Runs a command inside a Docker Compose container.
      #
      # @param cmd [String] The command to run.
      # @param opts [Hash] Options to pass to {Docker::Container#exec}.
      # @return [Specinfra::CommandResult] The result.
      # @api public
      def docker_compose_run!(cmd, opts = {})
        stdout, stderr, status = container.exec(['/bin/sh', '-c', cmd], opts)
        rspec_example_metadata(cmd, stdout.join, stderr.join)
        CommandResult.new(
          stdout: stdout.join, stderr: stderr.join, exit_status: status
        )
      rescue ::Docker::Error::DockerError
        raise
      rescue => e
        finalize
        erroneous_result(cmd, e)
      end

      # Starts Docker Compose and its containers.
      #
      # It also calculates the time to wait before running the tests.
      #
      # @return nil
      # @api private
      def do_start
        start_time = Time.new
        @compose.start
        do_wait((Time.new - start_time).to_i)
      end

      # Sleeps for some time if required.
      #
      # Reads the seconds to sleep from the `:docker_wait` Specinfra
      # configuration option.
      #
      # @param waited [Integer] The time already waited.
      # @return nil
      # @api private
      def do_wait(waited)
        wait = get_config(:docker_wait)
        return unless wait.is_a?(Integer) || wait.is_a?(Float)
        return if waited >= wait
        sleep(wait - waited)
      end
    end
  end
end
