require 'puppet'
require 'base64'
require 'json'
require 'socket'

Puppet::Reports.register_report(:zabbix) do

  config_file = File.join(File.dirname(Puppet.settings[:config]), "zabbix.yaml")
  raise(Puppet::ParseError, "Zabbix report config file #{config_file} not readable") unless File.exist?(config_file)
  config = YAML.load_file(config_file)
  HOST, PORT = config[:zabbix_host], config[:zabbix_port]

  desc <<-DESC
  Send puppet run data to zabbix.
  DESC

  def process
    send_items_to_zabbix
  end

  def connect
    return TCPSocket.new(HOST, PORT)
  end

  def disconnect(connection)
    connection.close unless connection.closed?
  end

  def data
    # Return a list of objects that meet the zabbix item data spec.
    clock = Time.now.to_i
    return [{
              :host  => self.host,
              :key   => 'puppet.run.date',
              :value => self.time.to_i,
              :clock => clock,
            },
            {
              :host  => self.host,
              :key   => 'puppet.run.status',
              :value => self.status,
              :clock => clock,
            },
            {
              :host  => self.host,
              :key   => 'puppet.run.time',
              :value => self.total,
              :clock => clock,
            },
            {
              :host  => self.host,
              :key   => 'puppet.version',
              :value => self.puppet_version,
              :clock => clock,
            }]
  end

  def request
    # Return an object that matches the request data spec.
    return {
      :request => 'agent data',
      :clock   => Time.now.to_i,
      :data    => data
    }
  end

  def send_items_to_zabbix
    begin
      # Ah, json...
      request_data = JSON.dump(request)

      # Get an open connection to the zabbix server.
      s = connect

      # Write the request data as specified by the zabbix send
      # protocol and flush the connection.
      s.write 'ZBXD\x01'
      s.write [request_data.size].pack('q')
      s.write request_data
      s.flush

      # Get the response from the server...
      header = s.read(5)

      # FIXME: ensure header matches expectation.

      datalen = s.read(8).unpack('q').shift
      raw_resp = s.read(datalen)
      resp = JSON.load(raw_resp)
      response = resp['response']
      Puppet.debug "Successfully sent puppet data to zabbix (#{HOST}) for #{self.host}."
    rescue => e
      Puppet.debug "Failed to send puppet data to zabbix (#{HOST}) for #{self.host}."
    ensure
      disconnect(s)
    end
  end

end
