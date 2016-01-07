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

require 'simplecov'
if ENV['TRAVIS']
  require 'coveralls'
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
end
SimpleCov.start do
  add_filter '/spec/'
end

require 'specinfra'
require 'specinfra/backend/docker_compose'
require 'specinfra/backend/docker_compose_lxc'
require 'docker'

Specinfra.configuration.backend(:base)

require 'should_not/rspec'

require 'support/docker_logger'
require 'support/rspec_filters'
require 'support/docker_compose_helpers'

RSpec.configure do |config|
  # Prohibit using the should syntax
  config.expect_with :rspec do |spec|
    spec.syntax = :expect
  end

  config.order = 'random'

  config.color = true
  config.tty = true

  config.filter_run_excluding lxc_driver: true unless lxc_execution_driver?

  config.before(:each) { DockerComposeHelpers.configuration_reset }
end
