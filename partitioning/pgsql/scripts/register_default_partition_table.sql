SELECT zabbix_maintaince.register_partition_table( 'EVENTS', 'CLOCK', 12, 3 );
SELECT zabbix_maintaince.register_partition_table( 'HISTORY_UINT', 'CLOCK', 1, 3 );
SELECT zabbix_maintaince.register_partition_table( 'HISTORY', 'CLOCK', 1, 3 );
SELECT zabbix_maintaince.register_partition_table( 'TRENDS_UINT', 'CLOCK', 12, 3 );
SELECT zabbix_maintaince.register_partition_table( 'TRENDS', 'CLOCK', 12, 3 );
