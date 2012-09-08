Zabbix Report Processor
=======================

Description
-----------
A Puppet report handler for sending data from puppet runs to [Zabbix](http://www.zabbix.com/).

Requirements
------------
* `json`
* `puppet`

Installation and Usage
----------------------
### Puppet Master and Agents
1. Install the `json` gem on the puppet master.

```bash
sudo gem install json
```

2. Install puppet-zabbix as a module in your puppet master's module
   path.

3. Update the `zabbix_host` and `zabbix_port` variables in
   `zabbix.yaml`. Copy `zabbix.yaml` to `/etc/puppet`.

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
