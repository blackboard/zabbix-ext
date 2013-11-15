SELECT zabbix_maintaince.register_housekeeper_table( 'SESSIONS', 'LASTACCESS', 365 );
SELECT zabbix_maintaince.register_housekeeper_table( 'ALERTS', 'CLOCK', 365 );
SELECT zabbix_maintaince.register_housekeeper_table( 'AUDITLOG', 'CLOCK', 365 );
SELECT zabbix_maintaince.register_housekeeper_table( 'SERVICE_ALARMS', 'CLOCK', 365 );
SELECT zabbix_maintaince.register_housekeeper_table( 'HISTORY_TEXT', 'CLOCK', 365 );
SELECT zabbix_maintaince.register_housekeeper_table( 'HISTORY_STR', 'CLOCK', 365 );
SELECT zabbix_maintaince.register_housekeeper_table( 'HISTORY_LOG', 'CLOCK', 365 );
