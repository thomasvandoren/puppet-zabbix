require 'base64'
require 'puppet'
require 'socket'
require 'yaml'

Puppet::Reports.register_report(:zabbix) do

  config_file = File.join(File.dirname(Puppet.settings[:config]), "zabbix.yaml")
  raise(Puppet::ParseError, "Zabbix report config file #{config_file} not readable") unless File.exist?(config_file)
  config = YAML.load_file(config_file)
  HOST, PORT, USER, PASS = config[:zabbix_host], config[:zabbix_port], config[:zabbix_user], config[:zabbix_pass]

  desc <<-DESC
  Send puppet run data to zabbix.
  DESC

  def process

  end

  def make_body(node, key, data)

  end

  def send_to_zabbix(node, key, data)
    
  end

end
