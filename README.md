Zabbix Report Processor
=======================

Description
-----------
A Puppet report handler for sending data from puppet runs to [Zabbix](http://www.zabbix.com/).

Requirements
------------
* `open4`
* `puppet`
* `zabbix_sender` binary (comes with zabbix-agent packages, usually)

Installation and Usage
----------------------
### Puppet Master and Agents
1. Install the `open4` gem on the puppet master.

```bash
sudo gem install open4
```

2. Install puppet-zabbix as a module in your puppet master's module
   path.

3. Update the `zabbix_host`, `zabbix_port`, and `zabbix_sender`
   variables in `zabbix.yaml`. Copy `zabbix.yaml` to `/etc/puppet`.

4. Enable pluginsync and reports on your master and clients in
   `puppet.conf`.

```ini
[main]
report     = true
pluginsync = true

[master]
reports = zabbix
```

5. Run the puppet client to sync the report as a plugin.

### Zabbix
1. Import the zabbix template in `doc/zabbix_template.xml`.

2. Link the template to hosts managed by puppet. Note that the
   "technical" host name will need to match the puppet certname
   (defaults to FQDN) for each host.

Author
------
Thomas Van Doren

License
-------
GPLv2
