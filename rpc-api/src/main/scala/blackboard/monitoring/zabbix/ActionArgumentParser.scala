package blackboard.monitoring.zabbix

import org.apache.commons.cli.{ GnuParser, CommandLine }
import com.typesafe.scalalogging.slf4j.Logging

object ActionArgumentParser extends Logging {
  private def OPTION_HOST = "host"
  private def OPTION_IP = "ip"
  private def OPTION_PORT = "port"
  private def OPTION_PROXY = "proxy"
  private def OPTION_METADATA = "metadata"
  private def OPTION_ACTION = "action"

  def parse(args: Seq[String]) = {
    val options = buildCmdOptions()
    val parser = new GnuParser();
    val line = parser.parse(options, args.toArray)
    val action = line.getOptionValue(OPTION_ACTION)
    val host = line.getOptionValue(OPTION_HOST)
    val ip = getOptionalArgument(line, OPTION_IP)
    val port = getOptionalArgument(line, OPTION_PORT)
    val proxy = getOptionalArgument(line, OPTION_PROXY)
    val metadata = getOptionalArgument(line, OPTION_METADATA)
    ActionArgument(action, host, ip, port, proxy, metadata)
  }

  private def getOptionalArgument(line: CommandLine, option: String) = {
    if (line.hasOption(option)) {
      val value = line.getOptionValue(option)
      if (null == value || value.equals("")) None else Some(value)
    } else {
      None
    }
  }

  private def buildCmdOptions() = {
    import org.apache.commons.cli.{ Options, Option }

    val options = new Options()

    val optHost = new Option(OPTION_HOST, true, "host name")
    optHost.setRequired(true)
    optHost.setArgs(1)
    optHost.setOptionalArg(false)
    options.addOption(optHost)

    val optIp = new Option(OPTION_IP, true, "ip address")
    optIp.setRequired(false)
    optIp.setArgs(1)
    optIp.setOptionalArg(true)
    options.addOption(optIp)

    val optPort = new Option(OPTION_PORT, true, "port number")
    optPort.setRequired(false)
    optPort.setArgs(1)
    optPort.setOptionalArg(true)
    options.addOption(optPort)

    val optProxy = new Option(OPTION_PROXY, true, "zabbix proxy")
    optProxy.setRequired(false)
    optProxy.setArgs(1)
    optProxy.setOptionalArg(true)
    options.addOption(optProxy)

    val optMetadata = new Option(OPTION_METADATA, true, "metadata")
    optMetadata.setRequired(false)
    optMetadata.setArgs(1)
    optMetadata.setOptionalArg(true)
    options.addOption(optMetadata)

    val actionMetadata = new Option(OPTION_ACTION, true, "action")
    actionMetadata.setRequired(true)
    actionMetadata.setArgs(1)
    actionMetadata.setOptionalArg(false)
    options.addOption(actionMetadata)
    
    options
  }
}

case class ActionArgument(action: String, host: String, ip: Option[String], port: Option[String],
  proxy: Option[String], metadata: Option[String])