#!/bin/sh

REMOTE_TMP_DIR=/tmp
LOG_FILE=deploy_agents_`date +"%Y_%m_%d_%H_%M_%S"`.log

usage()
{
  echo "usage: $0 [--server|-s] server [--user|-u] username [--pass|-p] password [--data|-d] datafile"
  echo "for example: $0 -s zabbix.pd.local -u root -p pass -d zabbix_list.data"
}

usage_and_exit()
{
  usage
  exit 1
}

################################################################################
# install agent on remote agent
# arguments:
#   remote host:        the hostname of the remote host
#   install directory:  the agent install directory on remote host
#   server:             the server address of the agent, for zabbix it's maybe zabbix.pd.local
#   user:               user name of the remote host
#   password:           password of the remote host
################################################################################
install_agent()
{
  remote_host=$1
  install_dir=$2
  server=$3
  user=$4
  password=$5
  
  echo "install agent on $remote_host:$install_dir for zabbix, server is $server"
  tools/invoke_remote_cmd.exp "$REMOTE_TMP_DIR/linux/install_agent.sh $install_dir $server > $REMOTE_TMP_DIR/linux/installation.log 2>&1" $remote_host $user $password
  
  if [ $? -ne 0 ]
  then
    echo "install agent on $remote_host:$install_dir for $agent_type failed" >> $LOG_FILE
  else
    echo "install agent on $remote_host:$install_dir for $agent_type successful" >> $LOG_FILE
  fi
}


################################################################################
# copy files to remote host temp directory
# arguments:
#   agent type:         the type of the agent
#   remote host:        the hostname of the remote host
#   user:               user name of the remote host
#   password:           password of the remote host
################################################################################
copy_files()
{
  remote_host=$1
  user=$2
  password=$3
  src_path=`dirname "$0"`/linux
  
  echo "remove installation files if there is"
  tools/invoke_remote_cmd.exp "rm -rf ${REMOTE_TMP_DIR}/linux" $remote_host $user $password
  
  echo "copy files from $src_path to $remote_host:$REMOTE_TMP_DIR for zabbix"
  tools/copy_files.exp $src_path $REMOTE_TMP_DIR $remote_host $user $password
}

# validate arguments
if [ $# -ne 8 ]
then
  usage_and_exit
fi

while test $# -gt 0
do
  case $1 in
  --server | -s )
    shift
    SERVER="$1"
    ;;
  --user | -u )
    shift
    USER="$1"
    ;;
  --pass | -p )
    shift
    PASS="$1"
    ;;
  --data | -d )
    shift
    DATA="$1"
    ;;
  *)
    usage_and_exit
    ;;
  esac
  shift
done

# check to see if expect is installed
expect -c "{exit}" > /dev/null 2>&1
if [ $? -ne 0 ]
then
  echo "expect required"
  exit 1
fi

# check data file
if [ ! -f $DATA ]
then
  echo "$DATA does not exist"
  exit 2
elif [ ! -r $DATA ]
then
  echo "$DATA not readable"
  exit 3
fi

# deploy agents
while IFS=, read host location
do
  echo '==================================================================='
  echo "install $TYPE agent on $host:/$location"
  copy_files $host $USER $PASS
  install_agent $host $location $SERVER $USER $PASS
done < $DATA

exit 0
