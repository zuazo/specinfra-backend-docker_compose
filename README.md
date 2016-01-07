# Specinfra Docker Compose Backend
[![Documentation](http://img.shields.io/badge/docs-rdoc.info-blue.svg?style=flat)](http://www.rubydoc.info/gems/specinfra-backend-docker_compose)
[![GitHub](http://img.shields.io/badge/github-zuazo/specinfra--backend--docker_compose-blue.svg?style=flat)](https://github.com/zuazo/specinfra-backend-docker_compose)
[![License](https://img.shields.io/github/license/zuazo/specinfra-backend-docker_compose.svg?style=flat)](#license-and-author)

[![Gem Version](https://badge.fury.io/rb/specinfra-backend-docker_compose.svg)](https://rubygems.org/gems/specinfra-backend-docker_compose)
[![Dependency Status](http://img.shields.io/gemnasium/zuazo/specinfra-backend-docker_compose.svg?style=flat)](https://gemnasium.com/zuazo/specinfra-backend-docker_compose)
[![Code Climate](http://img.shields.io/codeclimate/github/zuazo/specinfra-backend-docker_compose.svg?style=flat)](https://codeclimate.com/github/zuazo/specinfra-backend-docker_compose)
[![Travis CI Build Status](http://img.shields.io/travis/zuazo/specinfra-backend-docker_compose.svg?style=flat)](https://travis-ci.org/zuazo/specinfra-backend-docker_compose)
[![Circle CI Build Status](https://circleci.com/gh/zuazo/specinfra-backend-docker_compose/tree/master.svg?style=shield)](https://circleci.com/gh/zuazo/specinfra-backend-docker_compose/tree/master)
[![Coverage Status](http://img.shields.io/coveralls/zuazo/specinfra-backend-docker_compose.svg?style=flat)](https://coveralls.io/r/zuazo/specinfra-backend-docker_compose?branch=master)
[![Inline docs](http://inch-ci.org/github/zuazo/specinfra-backend-docker_compose.svg?branch=master&style=flat)](http://inch-ci.org/github/zuazo/specinfra-backend-docker_compose)

[Serverspec](http://serverspec.org/) / [Specinfra](https://github.com/mizzy/specinfra) backend for [Docker Compose](https://docs.docker.com/compose/).

## Requirements

* Recommended Docker `1.7.0` or higher.
* Docker Compose

## Installation

Add this line to your application's Gemfile:

```ruby
# Gemfile

gem 'specinfra-backend-docker_compose', '~> 0.1.0'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install specinfra-backend-docker_compose

## Usage

Create the [Docker Compose configuration](https://docs.docker.com/v1.8/compose/yml/) to test:

```yaml
# docker-compose.yml

web:
  build: .
  links:
  - db:mysql
  ports:
  - 8080:80

db:
  image: mariadb
  environment:
  - MYSQL_ROOT_PASSWORD=example
```

And a file example with some Serverspec tests:

```ruby
# web_test_spec.rb

require 'serverspec'
require 'specinfra/backend/docker_compose'

set :docker_compose_file, './docker-compose.yml'
set :docker_compose_container, :web # The compose container to test
set :docker_wait, 15 # wait 15 seconds before running the tests
set :backend, :docker_compose

describe 'docker-compose.yml run' do
  describe service('httpd') do
    it { should be_enabled }
    it { should be_running }
  end
end
```

To run the tests:

    $ rspec web_test_spec.rb

## Configuration

Uses the following `Specinfra` configuration options:

- `:docker_compose_file`: Docker Compose configuration file path (**required**).
- `:docker_compose_container`: The name of the container you want to test (**required**). Only one can be tested.
- `:docker_wait`: Seconds to wait for containers to start (i.e., time to sleep before running the tests) (**recommended**).
- `:backend`: `:docker_compose` or `:docker_compose_lxc` (for LXC execution driver). Always set it after all other options.

Keep in mind that some CI environments may be somewhat slower than usual. So maybe you will need to increase the `:docker_wait` value to one or two minutes to allow more time for services to start.

Some options used only by the `:docker_compose_lxc` backend:

- `:sudo_options`: Sudo command argument list as string or as array.
- `:sudo_path`: Sudo binary directory.
- `:sudo_password`
- `:disable_sudo`: whether to disable Sudo (enabled by default).

For example:

```ruby
set :sudo_password, '0deH3R7RbHoEwzIqQGCD'
```

## Important Warning

This code uses the [`docker-compose-api`](https://rubygems.org/gems/docker-compose-api) Ruby gem to emulate Docker Compose. So, some *docker-compose.yml* configuration options may not be supported yet or may not work exactly the same. Let us know if you find any bug or you need a missing feature.

Thanks to [Mauricio Klein](https://github.com/mauricioklein) for all his work by the way!

## Testing

See [TESTING.md](https://github.com/zuazo/specinfra-backend-docker_compose/blob/master/TESTING.md).

## Contributing

Please do not hesitate to [open an issue](https://github.com/zuazo/specinfra-backend-docker_compose/issues/new) with any questions or problems.

See [CONTRIBUTING.md](https://github.com/zuazo/specinfra-backend-docker_compose/blob/master/CONTRIBUTING.md).

## TODO

See [TODO.md](https://github.com/zuazo/specinfra-backend-docker_compose/blob/master/TODO.md).

## License and Author

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | [Xabier de Zuazo](https://github.com/zuazo) (<xabier@zuazo.org>)
| **Copyright:**       | Copyright (c) 2016 Xabier de Zuazo
| **License:**         | Apache License, Version 2.0

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
        http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
