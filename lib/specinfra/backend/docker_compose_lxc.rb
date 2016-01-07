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

require 'specinfra/backend/docker_compose'
require 'specinfra/backend/docker_lxc/exceptions'
require 'specinfra/backend/docker_lxc/shell_helpers'

# Command Execution Framework for Serverspec, Itamae and so on.
module Specinfra
  # Specinfra backend types.
  module Backend
    # Specinfra and Serverspec backend for Docker Compose using LXC execution
    # driver.
    class DockerComposeLxc < DockerCompose
      include Specinfra::Backend::DockerLxc::ShellHelpers

      protected

      # Generates `lxc-attach` command to run.
      #
      # @param cmd [String] The commands to run inside docker.
      # @return [Array] The command to run as unescaped array.
      def lxc_attach_command(cmd)
        id = container.id
        ['lxc-attach', '-n', id, '--', 'sh', '-c', cmd]
      end

      # Parses `lxc-attach` command output and raises an exception if it is an
      # error from the `lxc-attach` program.
      #
      # @param stderr [String] Command *stderr* output.
      # @param exit_status [Fixnum] Command exit status.
      # @return nil
      def lxc_attach_result_assert(stderr, exit_status)
        return if exit_status == 0
        return if stderr.match(/\A(lxc-attach|lxc_container|sudo): /).nil?
        fail DockerLxc::LxcAttachError, stderr
      end

      # Runs a command inside a Docker Compose container.
      #
      # @param cmd [String] The command to run.
      # @param opts [Hash] Options to pass to {Open3.popen3}.
      # @return [Specinfra::CommandResult] The result.
      # @api public
      def docker_compose_run!(cmd, opts = {})
        stdout, stderr, status = shell_command!(lxc_attach_command(cmd), opts)
        lxc_attach_result_assert(stderr, status)
        rspec_example_metadata(cmd, stdout, stderr)
        CommandResult.new(stdout: stdout, stderr: stderr, exit_status: status)
      rescue DockerLxc::LxcAttachError
        raise
      rescue => e
        finalize
        erroneous_result(cmd, e)
      end
    end
  end
end
