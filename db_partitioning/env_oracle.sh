#####################################################################
#config oracle specific paramters here if database is Oracle
#####################################################################
export ORACLE_SID=ENG11R2
export ORACLE_BASE=/usr/local/oracle
export ORACLE_HOME=$ORACLE_BASE/11gR2
PATH=$ORACLE_HOME/bin:$PATH
SQLPLUS="$ORACLE_HOME/bin/sqlplus -S "
EXP=$ORACLE_HOME/bin/exp

execute_sql_query()
{
  $SQLPLUS $DB_USER/$DB_PASS @$1 $2 $3 $4 $5 $6 $7
}

generate_script()
{
  execute_sql_query $SCRIPT_GENERATE_SCRIPT $SCRIPT_ZABBIX_CONVERTION_SCRIPT
}

backup_database()
{
  $EXP $DB_USER/$DB_PASS file=$DMP_FILE buffer=10240 log=$LOG
}

hourse_keep_database()
{
  execute_sql_query $SCRIPT_HOUSEKEEPER_CLEANUP
  execute_sql_query $SCRIPT_CHECK_HOUSEKEEPER_MAINTAIN_STATUS $ZABBIX_MAINTAIN_STATUS_FILE
}

drop_stage_table_database()
{
  execute_sql_query $SCRIPT_DROP_STAGE_TABLE $ARCH_TABLE_NAME $DROP_STAGE_FILE
}

update_archive_flag_database()
{
  execute_sql_query $SCRIPT_UPDATE_ARCHIVE_FLAG "Y" $DMP_FILE $ARCH_TABLE_NAME $ARCH_TABLE_PK $UPDATE_ARCHIVE_FLAG_FILE
}

archieve_table_database()
{
  $EXP $DB_USER/$DB_PASS file=$1 tables="($2)" buffer=10240 log=$3
}

check_partition_status_database()
{
  execute_sql_query $SCRIPT_CHECK_PARTITION_MAINTAIN_STATUS $ZABBIX_MAINTAIN_STATUS_FILE
}

get_stale_partition_tables_database()
{
  execute_sql_query $SCRIPT_CREATE_ZABBIX_ARCHIVE $ARCH_DATA_FILE
}