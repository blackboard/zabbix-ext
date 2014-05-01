Zabbix Extended
=================================

## What's Inside?
* Custom [Zabbix](http://www.zabbix.com/) templates for:
  * Blackboard Learn
  * Cassandra
  * ElasticSearch
  * MongoDB
  * PostgreSQL
  * Redis
  * Oracle Database
* [Zabbix](http://www.zabbix.com/) deployment tools:
  * Single agent deployment script
  * Bulk agent deployment script
* [Zabbix](http://www.zabbix.com/) elasticity tools:
  * Configuration of host groups, templates, and JMX interface in Zabbix agent config file
  * Auto deletion of hosts from Zabbix based on Zabbix agent visibilty thresholds
* [Zabbix](http://www.zabbix.com/) scalability tools:
  * Database partitioning script to replace housekeeping task by dropping partitions instead of running housekeeper's delete operations for purging data

## Requirements
* Zabbix 2.2 and up
* [monitor-bridge](https://github.com/blackboard/monitor-bridge) for ElasticSearch, MongoDB, PostgreSQL, Redis, and Oracle Database templates.

## HOWTOs
### Blackboard Learn Template
1. Deploy bb-extended-monitoring B2 on your Blackboard Learn instance located in templates/blackboard-learn/b2 folder
2. Import templates in templates/blackboard_learn to your Zabbix instance
3. Link the templates to the Blackboard Learn hosts in Zabbix

### ElasticSearch, MongoDB, PostgreSQL, Redis, Oracle Database
1. Deploy [monitor-bridge](https://github.com/blackboard/monitor-bridge)
2. Import templates/zbx_templates_extended.xml in Zabbix
3. In Zabbix, configure the JMX interface to point to [monitor-bridge](https://github.com/blackboard/monitor-bridge)
4. Link the templates

### Cassandra
1. Import templates/zbx_templates_extended.xml in Zabbix
2. Verify the JMX interface on your monitored host in Zabbix
3. Link the template to the monitored hosts
