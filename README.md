Zabbix Extended
=================================

## What's this for?
[Zabbix](http://www.zabbix.com/) Extended gives you the tools to scale your [Zabbix](http://www.zabbix.com/) servers and make management of your [Zabbix](http://www.zabbix.com) components elastic. It also provides you with custom templates to monitor popular technology stack that you're running but aren't supported by [Zabbix](http://www.zabbix.com/) out of the box.

## What's included?
* Custom templates
  * Blackboard Learn
  * Cassandra
  * ElasticSearch
  * MongoDB
  * PostgreSQL
  * Redis
  * Oracle Database
* Deployment
  * Single agent deployment script
  * Bulk agent deployment script
* Elasticity
  * Configuration of host groups, templates, and JMX interface in Zabbix agent config file
  * Auto deletion of hosts from Zabbix based on Zabbix agent visibilty thresholds
* Scalability
  * Database partitioning script to replace housekeeping task by dropping partitions instead of running housekeeper's delete operations for purging data

## Requirements
* Zabbix 2.2 and up
* monitor-bridge for custom templates (excludes Blackboard Learn template) - will be available in this repo soon

## HOWTOs
Coming soon!
