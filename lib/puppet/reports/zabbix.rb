require 'puppet'
require 'open4'
require 'tempfile'

Puppet::Reports.register_report(:zabbix) do

  config_file = File.join(File.dirname(Puppet.settings[:config]), "zabbix.yaml")
  raise(Puppet::ParseError, "Zabbix report config file #{config_file} not readable") unless File.exist?(config_file)
  config = YAML.load_file(config_file)
  HOST, PORT, ZABBIX_SENDER = config[:zabbix_host], config[:zabbix_port], config[:zabbix_sender]

  desc <<-DESC
  Send puppet run data to zabbix.
  DESC

  def process
    send_items_to_zabbix
  end

  def get_formatted_data
    formatted_data = [format_one_line(self.host, 'puppet.run.timestamp', self.time.to_i),
                      format_one_line(self.host, 'puppet.run.status',    self.status),
                      format_one_line(self.host, 'puppet.run.time',      get_total_time),
                      format_one_line(self.host, 'puppet.version',       self.puppet_version),]
    return formatted_data.join("\n")
  end

  def get_total_time
    # Returns the total time metric. Return 0.0 if the status is
    # failed.
    return 0.0 if self.status == 'failed'
    self.metrics['time'].values.each { |val|
      return val[2] if val[0] = 'total'
    }
  end

  # Returns the zabbix_sender command line call.
  def get_zabbix_sender(zabbix_sender, host, port, input_file)
    return "#{zabbix_sender} --zabbix-server #{host} --port #{port} --input-file #{input_file}"
  end

  def format_one_line(host, key, value)
    return "#{host} #{key} #{value}"
  end

  def send_items_to_zabbix
    begin
      input_file = Tempfile.new('puppet.report.zabbix')
      input_file.write(get_formatted_data)

      zabbix_sender_cmd = get_zabbix_sender(ZABBIX_SENDER, HOST, PORT, input_file.path)

      status = Open4::popen4(zabbix_sender_cmd) do |pid, stdin, stdout, stderr|
        stdin.close
        out_put = stdout.read.strip
        err_put = stdout.read.strip
      end

      Puppet.debug("Zabbix sender stderr: #{out_put}")
      Puppet.debug("Zabbix sender stdout: #{out_put}")

      if status.exitstatus == 0
        Puppet.debug("Successfuly sent puppet data to zabbix for #{self.host}.")
      else
        Puppet.warn("Failed to send puppet data to zabbix (#{HOST}:#{PORT}) for #{self.host}")
      end
    ensure
      input_file.close
      input_file.unlink
    end
  end

end
