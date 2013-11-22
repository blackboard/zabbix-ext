#!/bin/sh

BASE_DIR=$(dirname $0)
if [ $BASE_DIR = '.' ] 
then
  BASE_DIR=$PWD
fi

. $BASE_DIR/env.sh

$DB_QUERY_TOOL -U $DB_USER -w -f $SCRIPT_HOUSEKEEPER_CLEANUP

$DB_QUERY_TOOL -U $DB_USER -w -f $SCRIPT_CHECK_HOUSEKEEPER_MAINTAIN_STATUS > $ZABBIX_MAINTAIN_STATUS_FILE
grep 'SUCCESSFUL' $ZABBIX_MAINTAIN_STATUS_FILE > /dev/null
if [ $? -ne 0 ]
then
  MSG="Housekeeper cleanup - FAILED!"
  partition_msg_sender
else
  MSG="Housekeeper cleanup - SUCCESSFUL!"
  partition_msg_sender  
fi
