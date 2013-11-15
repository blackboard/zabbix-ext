#!/bin/sh

BASE_DIR=$(dirname $0)
if [ $BASE_DIR == '.' ] 
then
  BASE_DIR=$PWD
fi

. $BASE_DIR/env.sh

## Drop the stage table from database 
drop_stage_table()
{
  VARS=`echo -v v_table_name=\'$ARCH_TABLE_NAME\'`
  $DB_QUERY_TOOL -U $DB_USER -w -f $SCRIPT_DROP_STAGE_TABLE $VARS 2> $DROP_STAGE_FILE
  grep -i 'ERROR' $DROP_STAGE_FILE
  if [ $? -eq 0 ]
  then
    MSG="Drop the $ARCH_TABLE_NAME table - FAILED!"
  else
    MSG="Drop the $ARCH_TABLE_NAME table - SUCCESSFUL!"
  fi   
  partition_msg_sender
}

## Update the flag of archived partition
update_archive_flag()
{
  VARS=`echo  -v v_archive_ind=\'Y\' -v v_archive_full_path=\'$DMP_FILE\' -v v_arch_table_name=\'$ARCH_TABLE_NAME\' -v v_zabbix_partition_pk1=\'$ARCH_TABLE_PK\'`
  $DB_QUERY_TOOL -U $DB_USER -w -f $SCRIPT_UPDATE_ARCHIVE_FLAG $VARS 2> $UPDATE_ARCHIVE_FLAG_FILE
  grep -i 'ERROR' $UPDATE_ARCHIVE_FLAG_FILE
  if [ $? -eq 0 ]
  then
    MSG='Update the archive flag - FAILED!' 
    partition_msg_sender
  else
    MSG="Archive the $ARCH_TABLE_NAME table - SUCCESSFUL!"
    partition_msg_sender
    drop_stage_table
  fi   
}

## Archive the stale partition data
archive_table()
{
  for arch_data in `grep 'ARCH:' $ARCH_DATA_FILE|awk -F ":" '{print $2}'`
  do    
    ARCH_TABLE_PK=$(echo $arch_data|awk -F "," '{print $1}')
    ARCH_TABLE_NAME=$(echo $arch_data|awk -F "," '{print $2}')
    DMP_FILE=$ARCH_DIR/$ARCH_TABLE_NAME.$(date +"%Y_%m_%d").dmp
    LOG_FILE=$ARCH_DIR/$ARCH_TABLE_NAME.$(date +"%Y_%m_%d").log
    $DB_BACKUP_TOOL -U $DB_USER -w -f $DMP_FILE -t "$ARCH_TABLE_NAME" -v 2> $LOG_FILE
    if [ $? -ne 0 ]
    then
      MSG="Archive the $ARCH_TABLE_NAME table - FAILED!"
    else
      update_archive_flag
    fi
  done   
}

## Prebuild the new partitions 
$DB_QUERY_TOOL -U $DB_USER -w -f $SCRIPT_ZABBIX_ADD_PARTITION

## Remove the stale partitions
$DB_QUERY_TOOL -U $DB_USER -w -f $SCRIPT_ZABBIX_REMOVE_PARTITION

## Check the status of partition maintain
$DB_QUERY_TOOL -U $DB_USER -w -f $SCRIPT_CHECK_PARTITION_MAINTAIN_STATUS > $ZABBIX_MAINTAIN_STATUS_FILE
grep 'SUCCESSFUL' $ZABBIX_MAINTAIN_STATUS_FILE > /dev/null
if [ $? -ne 0 ]
then
  MSG="Maintain the zabbix partition - FAILED!"
  partition_msg_sender
else
  MSG="Maintain the zabbix partition - SUCCESSFUL!"
  partition_msg_sender  
fi

## Get the stale partition name
## Housekeeper cleanup
$BASE_DIR/housekeeper_cleanup.sh

$DB_QUERY_TOOL -U $DB_USER -w -f $SCRIPT_CREATE_ZABBIX_ARCHIVE > $ARCH_DATA_FILE
grep -i 'ERROR' $ARCH_DATA_FILE > /dev/null
if [ $? -eq 0 ] 
then
  MSG='Get the archive table - FAILED!'
  partition_msg_sender
  exit 1;
fi

grep -i 'ARCH:' $ARCH_DATA_FILE > /dev/null
if [ $? -ne 0 ] 
then
  MSG='Nothing need to be archived now - SUCCESSFUL!'
  partition_msg_sender
else
## Archive the stale partition data
  archive_table
fi

## Backup the database
$BASE_DIR/zabbix_backup.sh

