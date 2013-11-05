#!/bin/sh

BASE_DIR=$(dirname $0)
if [ $BASE_DIR = '.' ] 
then
  BASE_DIR=$PWD
fi

. env.sh

mkdir $BAK_DIR
#chown -R oracle:oinstall $BAK_DIR
$EXP $DB_USER/$DB_PASS file=$DMP_FILE buffer=10240 log=$LOG
if [ $? -ne 0 ]; then
  $ZABBIX_AGENT/bin/zabbix_sender -z $ZABBIX_SERVER -s "Zabbix server" -k zbx_db_backup -o "Zabbix DB backup FAILED"
else
  $ZABBIX_AGENT/bin/zabbix_sender -z $ZABBIX_SERVER -s "Zabbix server" -k zbx_db_backup -o "Zabbix DB backup SUCCESSFUL"
fi

# clean up the backup older than 30 days
find $BAK_DIR -maxdepth 1 -mtime +30 -type d -print0 | xargs -0 rm -rf

