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

# Print docker chunk logs.
class DockerLogger
  # Docker Logger constructor.
  def intialize
    @status = nil
  end

  def parse_chunk(chunk)
    return chunk if chunk.is_a?(Hash)
    JSON.parse(chunk)
  rescue JSON::ParserError
    { 'stream' => chunk }
  end

  def print_status(status)
    if status != @status
      puts
      @status = status
      print "#{status}." unless status.nil?
    elsif !status.nil?
      print '.'
    end
    STDOUT.flush
  end

  def print_chunk(chunk)
    chunk_json = parse_chunk(chunk)
    print_status(chunk_json['status'])
    return unless chunk_json.key?('stream')
    puts chunk_json['stream']
  end
end
