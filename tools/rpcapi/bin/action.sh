#!/bin/sh
export JAVA_HOME=/usr/local/jdk7
export SCALA_HOME=/usr/local/scala
script_path=`dirname "$0"`
cd $script_path
base_dir=$(pwd)
exec $SCALA_HOME/bin/scala -Dconfig.file=${base_dir}/application.conf -Dlogback.configurationFile=${base_dir}/logback.xml -Dbase.dir=${base_dir} -cp ${base_dir}/rpc-api-assembly-0.1.jar "$0" "$@"
!#

import blackboard.monitoring.zabbix._
import com.typesafe.scalalogging.slf4j.Logging

object Main extends Logging {
  def start(params: Seq[String]) = {
    try {
      val actionArgument = ActionArgumentParser.parse(params)
      ActionFactory.get(actionArgument).get.execute()
    } catch {
      case e: Throwable => logger.error("Add host failed", e)
    }
  }
}

Main.start(args.toSeq)