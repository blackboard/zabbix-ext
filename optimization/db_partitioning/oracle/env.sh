#set -x 

DB_USER=zabbix
DB_PASS=zabbix  

export ORACLE_SID=ENG11R2
export ORACLE_BASE=/usr/local/oracle
export ORACLE_HOME=$ORACLE_BASE/11gR2
PATH=$ORACLE_HOME/bin:$PATH

SQLPLUS="$ORACLE_HOME/bin/sqlplus -S "
EXP=$ORACLE_HOME/bin/exp

ZABBIX_AGENT=/mnt/storage/zabbix
ZABBIX_SERVER=zabbix.pd.local

BASE_DIR=$(dirname $0)
if [ $BASE_DIR = '.' ] 
then
  BASE_DIR=$PWD
fi

ARCH_DIR=$BASE_DIR/arch
BAK_DIR=$BASE_DIR/backup/$(date +"%Y_%m_%d")

LOG=$BAK_DIR/backup.log
DMP_FILE=$BAK_DIR/zabbix_bak.dmp

ARCH_DATA_FILE=$ARCH_DIR/zabbix_archive.txt
DROP_STAGE_FILE=$ARCH_DIR/drop_stage_table.txt
UPDATE_ARCHIVE_FLAG_FILE=$ARCH_DIR/update_archive_flag.txt
ZABBIX_MAINTAIN_STATUS_FILE=$ARCH_DIR/zabbix_maintain_status.txt

SCRIPT_DIR=$BASE_DIR/scripts
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
SCRIPT_ZABBIX_CONVERTION_SCRIPT=$BASE_DIR/zabbix_convertion_script.sql


## Send the message by zabbix agent
msg_sender()
{
  echo $MSG
#  $ZABBIX_SENDER -z $ZABBIX_SERVER -s "$ZABBIX_SERVER_NAME" -k "$ZABBIX_MSG_KEY" -o "$MSG"
}

## Send the partition message by zabbix agent
partition_msg_sender()
{
  ZABBIX_MSG_KEY=$ZABBIX_PARTITION_MSG_KEY
  msg_sender
}

## Send the backup message by zabbix agent
backup_msg_sender()
{
  ZABBIX_MSG_KEY=$ZABBIX_BACKUP_MSG_KEY
  msg_sender
}

