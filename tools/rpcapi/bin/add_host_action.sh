#!/bin/sh
export JAVA_HOME=/usr/local/jdk7
export SCALA_HOME=/usr/local/scala
base_dir=$(pwd)
exec $SCALA_HOME/bin/scala -cp ${base_dir}/rpc-api-assembly-0.1.jar "$0" "$@"
!#

blackboard.monitoring.zabbix._

val actionArgument = ActionArgumentParser.parse(args)
ActionFactory.get(ActionFactory.ACTION_CREATE_HOST)(actionArgument).execute()