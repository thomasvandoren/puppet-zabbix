Zabbix Report Processor
=======================
[![Build Status](https://secure.travis-ci.org/thomasvandoren/puppet-zabbix.png)](http://travis-ci.org/thomasvandoren/puppet-zabbix)

Description
-----------

A Puppet report handler for sending data from puppet runs to
[Zabbix](http://www.zabbix.com/).

Requirements
------------
* `open4`
* `puppet`
* `zabbix_sender` binary (comes with zabbix-agent packages, usually)

Installation and Usage
----------------------
### Puppet Master and Agents
* Install the `open4` gem on the puppet master.

```bash
sudo gem install open4
```

* Install puppet-zabbix as a module in your puppet master's module
  path.

* Update the `zabbix_host`, `zabbix_port`, and `zabbix_sender`
  variables in `zabbix.yaml`. Copy `zabbix.yaml` to `/etc/puppet`.

* Enable pluginsync and reports on your master and clients in
  `puppet.conf`.

```ini
[main]
report     = true
pluginsync = true

[master]
reports = zabbix
```

* Run the puppet client to sync the report as a plugin.

### Zabbix
* Import the zabbix template in `doc/zabbix_template.xml`.

* Link the template to hosts managed by puppet. Note that the
  "technical" host name will need to match the puppet certname
  (defaults to FQDN) for each host.

Author
------
Thomas Van Doren

License
-------
GPLv2
