#!/bin/sh

# check to see if the script is running as root user
if [ "`whoami`" != "root" ] ; then
  echo "This must be run as root user."
  exit -1
fi

# get input params
if [ $# -lt 2 ]
then
  echo "Error in $0 - Invalid Argument Count"
  echo "Syntax: $0 install_dir zabbix_server"
  echo "Syntax Example: $0 /mnt/storage/zabbix r5x64o11-px017"
  exit
fi
install_dir=$1
zabbix_server=$2

# create group
group=$(cat /etc/group | grep zabbix)
if [ -z ${group} ]; then
  echo "Creating zabbix group"
  groupadd zabbix
else
  echo "zabbix group already exists"
fi

# create user
user=$(cat /etc/passwd | grep zabbix)
if [ -z ${user} ]; then
  echo "Creating zabbix user"
  useradd -g zabbix zabbix
else
  echo "zabbix user already exists"
fi

# set work directory 
script_path=`dirname "$0"`
cd $script_path

# kill the zabbix_agentd process and clear installation directory
killall -9 zabbix_agentd
rm -rf ${install_dir}

# clear the zabbix install files
rm -rf zabbix-*

# compile and install zabbix agent
tar -zxvf zabbix.tar.gz
cd zabbix-*
./configure --prefix=${install_dir} --enable-agent
make
make install

# use the first server as the active server
active_server=$(echo $zabbix_server|awk -F , '{print $1}')

# Configure zabbix agent
sed -i "s%LogFile=/tmp/zabbix_agentd.log%LogFile=$install_dir/logs/zabbix_agentd.log%g" ${install_dir}/etc/zabbix_agentd.conf
sed -i "s/Hostname=Zabbix server/Hostname=`hostname`/" ${install_dir}/etc/zabbix_agentd.conf
sed -i "s/Server=127.0.0.1/Server=$zabbix_server/" ${install_dir}/etc/zabbix_agentd.conf
sed -i "s/ServerActive=127.0.0.1/ServerActive=$active_server/" ${install_dir}/etc/zabbix_agentd.conf
sed -i "s%# PidFile=/tmp/zabbix_agentd.pid%PidFile=${install_dir}/tmp/zabbix_agentd.pid%" ${install_dir}/etc/zabbix_agentd.conf
sed -i "s%# HostMetadata=%HostMetadata=linux%" ${install_dir}/etc/zabbix_agentd.conf

# add some user parameters from ../../user_parameters
user_paramters_dir=../user_parameters
for each in `ls $user_paramters_dir`
do 
  cp $user_paramters_dir/$each ${install_dir}/etc
  echo "Include=${install_dir}/etc/${each}" >> ${install_dir}/etc/zabbix_agentd.conf
done

# create logs dir
mkdir ${install_dir}/logs
chown -R zabbix:zabbix ${install_dir}/logs

# create tmp dir
mkdir ${install_dir}/tmp
chown -R zabbix:zabbix ${install_dir}/tmp

# setup service
rm -rf /etc/init.d/zabbix_agentd
cp misc/init.d/fedora/core/zabbix_agentd /etc/init.d/zabbix_agentd
sed -i "s%BASEDIR=/usr/local%BASEDIR=$install_dir%g" /etc/init.d/zabbix_agentd
sed -i "s%PIDFILE=/tmp%PIDFILE=$install_dir/tmp/%g" /etc/init.d/zabbix_agentd
chmod +x /etc/init.d/zabbix_agentd
chkconfig zabbix_agentd on

# start the service
service zabbix_agentd start

# check if the service is started
sleep 1
result=$(ps -el|grep zabbix_agentd)
if [ -z "${result}" ]
then
  exit 100
else
  exit 0
fi