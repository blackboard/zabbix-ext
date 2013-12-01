#####################################################################
#config postgresql specific paramters here if database is Oracle
#####################################################################
PATH=/usr/bin:$PATH
DB_QUERY_TOOL="psql -q "
DB_BACKUP_TOOL="pg_dump -F c -v "

#####################################################################
#do not touch these parameters unless you know what you are doing
#####################################################################
SCRIPT_ZABBIX_CONVERTION_SCRIPT_TEMP=$SCRIPT_DIR/.convertion_script_temp.sql

execute_sql_query()
{
  $DB_QUERY_TOOL -U $DB_USER -w $DB_PASS -f $1
}

generate_script()
{
  $DB_QUERY_TOOL -U $DB_USER -w -f $SCRIPT_GENERATE_SCRIPT 2> $SCRIPT_ZABBIX_CONVERTION_SCRIPT_TEMP
  awk -F "NOTICE:" '/NOTICE:/ {print $2}' $SCRIPT_ZABBIX_CONVERTION_SCRIPT_TEMP | sed 's/^[ \t]*//g' | tee $SCRIPT_ZABBIX_CONVERTION_SCRIPT 
  rm -f $SCRIPT_ZABBIX_CONVERTION_SCRIPT_TEMP
}

backup_database()
{
  $DB_BACKUP_TOOL -U $DB_USER -w -f $DMP_FILE -o 
}

hoursekeep_database()
{
  $DB_QUERY_TOOL -U $DB_USER -w -f $SCRIPT_HOUSEKEEPER_CLEANUP
  $DB_QUERY_TOOL -U $DB_USER -w -f $SCRIPT_CHECK_HOUSEKEEPER_MAINTAIN_STATUS > $ZABBIX_MAINTAIN_STATUS_FILE
}

drop_stage_table_database()
{
  VARS=`echo -v v_table_name=\'$ARCH_TABLE_NAME\'`
  $DB_QUERY_TOOL -U $DB_USER -w -f $SCRIPT_DROP_STAGE_TABLE $VARS 2> $DROP_STAGE_FILE
}

update_archive_flag_database()
{
  VARS=`echo  -v v_archive_ind=\'Y\' -v v_archive_full_path=\'$DMP_FILE\' -v v_arch_table_name=\'$ARCH_TABLE_NAME\' -v v_zabbix_partition_pk1=\'$ARCH_TABLE_PK\'`
  $DB_QUERY_TOOL -U $DB_USER -w -f $SCRIPT_UPDATE_ARCHIVE_FLAG $VARS 2> $UPDATE_ARCHIVE_FLAG_FILE
}

archieve_table_database()
{
  $DB_BACKUP_TOOL -U $DB_USER -w -f $1 -t "$2" -v 2> $3
}

check_partition_status_database()
{
  $DB_QUERY_TOOL -U $DB_USER -w -f $SCRIPT_CHECK_PARTITION_MAINTAIN_STATUS > $ZABBIX_MAINTAIN_STATUS_FILE
}

get_stale_partition_tables_database()
{
  $DB_QUERY_TOOL -U $DB_USER -w -f $SCRIPT_CREATE_ZABBIX_ARCHIVE > $ARCH_DATA_FILE
}