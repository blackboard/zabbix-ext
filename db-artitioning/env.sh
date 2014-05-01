#set -x 

BASE_DIR=$(dirname $0)
if [ $BASE_DIR = '.' ] 
then
  BASE_DIR=$PWD
fi

#####################################################################
#config the archieve directory and backup directory
#####################################################################
ARCH_DIR=$BASE_DIR/arch
BAK_DIR=$BASE_DIR/backup/$(date +"%Y_%m_%d")

#####################################################################
#config database username and password
#####################################################################
DB_USER=zabbix
DB_PASS=zabbix
DB_TYPE=oracle #oracle|pgsql


#####################################################################
#do not touch these parameters unless you know what you are doing
#####################################################################
LOG=$BAK_DIR/backup.log
DMP_FILE=$BAK_DIR/zabbix_bak.dmp

ARCH_DATA_FILE=$ARCH_DIR/zabbix_archive.txt
DROP_STAGE_FILE=$ARCH_DIR/drop_stage_table.txt
UPDATE_ARCHIVE_FLAG_FILE=$ARCH_DIR/update_archive_flag.txt
ZABBIX_MAINTAIN_STATUS_FILE=$ARCH_DIR/zabbix_maintain_status.txt

if [ $DB_TYPE = 'oracle' ] 
then
  . $BASE_DIR/env_oracle.sh
  SCRIPT_DIR=$BASE_DIR/oracle
else
  . $BASE_DIR/env_pgsql.sh
  SCRIPT_DIR=$BASE_DIR/pgsql
fi
SCRIPT_CREATE_ZABBIX_ARCHIVE=$SCRIPT_DIR/create_zabbix_archive.sql
SCRIPT_CHECK_PARTITION_MAINTAIN_STATUS=$SCRIPT_DIR/check_partition_maintaince_status.sql
SCRIPT_ZABBIX_REMOVE_PARTITION=$SCRIPT_DIR/zabbix_remove_partition.sql
SCRIPT_ZABBIX_ADD_PARTITION=$SCRIPT_DIR/zabbix_add_partition.sql
SCRIPT_DROP_STAGE_TABLE=$SCRIPT_DIR/drop_stage_table.sql
SCRIPT_UPDATE_ARCHIVE_FLAG=$SCRIPT_DIR/update_archive_flag.sql
SCRIPT_CHECK_HOUSEKEEPER_MAINTAIN_STATUS=$SCRIPT_DIR/check_housekeeper_maintaince_status.sql
SCRIPT_HOUSEKEEPER_CLEANUP=$SCRIPT_DIR/housekeeper_cleanup.sql
SCRIPT_ZABBIX_MAINTAINCE=$SCRIPT_DIR/zabbix_maintaince.sql
SCRIPT_REGISTER_DEFAULT_HOUSEKEEPER_TABLE=$SCRIPT_DIR/register_default_housekeeper_table.sql
SCRIPT_REGISTER_DEFAULT_PARTITION_TABLE=$SCRIPT_DIR/register_default_partition_table.sql
SCRIPT_CONVERT_TO_PARTITION=$SCRIPT_DIR/convert_to_partition.sql
SCRIPT_GENERATE_SCRIPT=$SCRIPT_DIR/generate_script.sql
SCRIPT_ZABBIX_CONVERTION_SCRIPT=$SCRIPT_DIR/zabbix_convertion_script.sql

## log the message
log_msg()
{
  echo $1
}

## Set up register tables and stored procedures/functions
setup_register_tables()
{
  execute_sql_query $SCRIPT_ZABBIX_MAINTAINCE
}

## Register default values about which tables to partition/housekeeping
register_default_values()
{
  execute_sql_query $SCRIPT_REGISTER_DEFAULT_HOUSEKEEPER_TABLE
  execute_sql_query $SCRIPT_REGISTER_DEFAULT_PARTITION_TABLE
}

## Partition database initially
partition()
{
  execute_sql_query $SCRIPT_CONVERT_TO_PARTITION 
}

## Backup zabbix database
backup()
{
  mkdir $BAK_DIR
  
  # clean up the backup older than 30 days
  find $BAK_DIR -maxdepth 1 -mtime +30 -type d -print0 | xargs -0 rm -rf
  
  backup_database
  
  if [ $? -ne 0 ]; then
    log_msg "Zabbix DB backup FAILED"
    exit -1
  else
    log_msg "Zabbix DB backup SUCCESSFUL"
    exit 0
  fi
}

## Clean up the tables
hoursekeep()
{
  hoursekeep_database
  grep 'SUCCESSFUL' $ZABBIX_MAINTAIN_STATUS_FILE > /dev/null
  if [ $? -ne 0 ]
  then
    log_msg "Housekeeper cleanup - FAILED!"
  else
    log_msg "Housekeeper cleanup - SUCCESSFUL!"
  fi
}

drop_stage_table()
{
  drop_stage_table_database
  grep -i 'ERROR' $DROP_STAGE_FILE
  if [ $? -eq 0 ]
  then
    log_msg "Drop the $ARCH_TABLE_NAME table - FAILED!"
  else
    log_msg "Drop the $ARCH_TABLE_NAME table - SUCCESSFUL!"
  fi
}

## Update the flag of archived partition
update_archive_flag()
{
  update_archive_flag_database
  grep -i 'ERROR' $UPDATE_ARCHIVE_FLAG_FILE
  if [ $? -eq 0 ]
  then
    log_msg 'Update the archive flag - FAILED!' 
  else
    log_msg "Archive the $ARCH_TABLE_NAME table - SUCCESSFUL!"
    drop_stage_table
  fi   
}

## Archive the stale partition data
archive_table()
{
  for arch_data in `grep '^ARCH:' $ARCH_DATA_FILE|awk -F ":" '{print $2}'`
  do    
    ARCH_TABLE_PK=$(echo $arch_data|awk -F "," '{print $1}')
    ARCH_TABLE_NAME=$(echo $arch_data|awk -F "," '{print $2}')
    DMP_FILE=$ARCH_DIR/$ARCH_TABLE_NAME.$(date +"%Y_%m_%d").dmp
    LOG_FILE=$ARCH_DIR/$ARCH_TABLE_NAME.$(date +"%Y_%m_%d").log
    archieve_table_database $DMP_FILE $ARCH_TABLE_NAME $LOG_FILE
    if [ $? -ne 0 ]
    then
      log_msg "Archive the $ARCH_TABLE_NAME table - FAILED!"
    else
      update_archive_flag
    fi
  done   
}

check_partition_status()
{
  check_partition_status_database
  grep 'SUCCESSFUL' $ZABBIX_MAINTAIN_STATUS_FILE > /dev/null
  if [ $? -ne 0 ]
  then
    log_msg "Maintain the zabbix partition - FAILED!"
  else
    log_msg "Maintain the zabbix partition - SUCCESSFUL!"
  fi
}

get_stale_partition_tables()
{
  get_stale_partition_tables_database
  grep -i 'ERROR' $ARCH_DATA_FILE > /dev/null
  if [ $? -eq 0 ] 
  then
    MSG='Get the archive table - FAILED!'
    partition_msg_sender
    exit 1;
  fi
}
