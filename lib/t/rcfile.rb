require 'singleton'
require 'yaml'

class RCFile
  FILE_NAME = '.trc'
  attr_reader :path

  include Singleton

  def initialize
    @path = File.join(File.expand_path("~"), FILE_NAME)
    @data = load
  end

  def [](username)
    profiles[username]
  end

  def []=(username, profile)
    profiles[username] ||= {}
    profiles[username].merge!(profile)
    write
  end

  def configuration
    @data['configuration']
  end

  def active_consumer_key
    profiles[active_profile[0]][active_profile[1]]['consumer_key'] if active_profile && profiles[active_profile[0]] && profiles[active_profile[0]][active_profile[1]]
  end

  def active_consumer_secret
    profiles[active_profile[0]][active_profile[1]]['consumer_secret'] if active_profile && profiles[active_profile[0]] && profiles[active_profile[0]][active_profile[1]]
  end

  def active_profile
    configuration['default_profile']
  end

  def active_profile=(profile)
    configuration['default_profile'] = [profile['username'], profile['consumer_key']]
    write
  end

  def active_secret
    profiles[active_profile[0]][active_profile[1]]['secret'] if active_profile && profiles[active_profile[0]] && profiles[active_profile[0]][active_profile[1]]
  end

  def active_token
    profiles[active_profile[0]][active_profile[1]]['token'] if active_profile && profiles[active_profile[0]] && profiles[active_profile[0]][active_profile[1]]
  end

  def delete
    File.delete(@path) if File.exist?(@path)
  end

  def empty?
    @data == default_structure
  end

  def load
    YAML.load_file(@path)
  rescue Errno::ENOENT
    default_structure
  end

  def path=(path)
    @path = path
    @data = load
    @path
  end

  def profiles
    @data['profiles']
  end

  def reset
    self.send(:initialize)
  end

private

  def default_structure
    {'configuration' => {}, 'profiles' => {}}
  end

  def write
    File.open(@path, File::RDWR|File::TRUNC|File::CREAT, 0600) do |rcfile|
      rcfile.write @data.to_yaml
    end
  end

end
