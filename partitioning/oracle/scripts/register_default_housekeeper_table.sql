EXEC zabbix_maintaince.register_housekeeper_table( p_table_name => 'SESSIONS', p_del_cond_col_name => 'LASTACCESS', p_reserve_days => 365 );
EXEC zabbix_maintaince.register_housekeeper_table( p_table_name => 'ALERTS', p_del_cond_col_name => 'CLOCK', p_reserve_days => 365 );
EXEC zabbix_maintaince.register_housekeeper_table( p_table_name => 'AUDITLOG', p_del_cond_col_name => 'CLOCK', p_reserve_days => 365 );
EXEC zabbix_maintaince.register_housekeeper_table( p_table_name => 'SERVICE_ALARMS', p_del_cond_col_name => 'CLOCK', p_reserve_days => 365 );
EXEC zabbix_maintaince.register_housekeeper_table( p_table_name => 'HISTORY_TEXT', p_del_cond_col_name => 'CLOCK', p_reserve_days => 365 );
EXEC zabbix_maintaince.register_housekeeper_table( p_table_name => 'HISTORY_STR', p_del_cond_col_name => 'CLOCK', p_reserve_days => 365 );
EXEC zabbix_maintaince.register_housekeeper_table( p_table_name => 'HISTORY_LOG', p_del_cond_col_name => 'CLOCK', p_reserve_days => 365 );
EXIT;
