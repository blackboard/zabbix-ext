#!/bin/sh

BASE_DIR=$(dirname $0)
if [ $BASE_DIR == '.' ] 
then
  BASE_DIR=$PWD
fi

. $BASE_DIR/env.sh

mkdir -p $ARCH_DIR
mkdir -p $BAK_DIR

## Prebuild the new partitions 
execute_sql_query $SCRIPT_ZABBIX_ADD_PARTITION

## Remove the stale partitions
execute_sql_query  $SCRIPT_ZABBIX_REMOVE_PARTITION

## Check the status of partition maintain
check_partition_status

## Get the stale partition table names
get_stale_partition_tables

## Housekeeper cleanup
hoursekeep

grep -i 'ARCH:' $ARCH_DATA_FILE > /dev/null
if [ $? -ne 0 ] 
then
  log_msg 'Nothing need to be archived now - SUCCESSFUL!'
else
  ## Archive the stale partition data
  archive_table
fi

## Backup the database
backup

