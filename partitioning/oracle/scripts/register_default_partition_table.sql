EXEC zabbix_maintaince.register_partition_table( p_table_name => 'EVENTS', p_partition_key => 'CLOCK', p_reserve_months => 12, p_prebuild_months => 3 );
EXEC zabbix_maintaince.register_partition_table( p_table_name => 'HISTORY_UINT', p_partition_key => 'CLOCK', p_reserve_months => 1, p_prebuild_months => 3 );
EXEC zabbix_maintaince.register_partition_table( p_table_name => 'HISTORY', p_partition_key => 'CLOCK', p_reserve_months => 1, p_prebuild_months => 3 );
EXEC zabbix_maintaince.register_partition_table( p_table_name => 'TRENDS_UINT', p_partition_key => 'CLOCK', p_reserve_months => 12, p_prebuild_months => 3 );
EXEC zabbix_maintaince.register_partition_table( p_table_name => 'TRENDS', p_partition_key => 'CLOCK', p_reserve_months => 12, p_prebuild_months => 3 );
EXIT;
