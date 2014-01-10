package blackboard.monitoring.zabbix

import com.typesafe.scalalogging.slf4j.Logging
import com.typesafe.config.ConfigFactory
import play.api.libs.json._

object ActionFactory extends Logging {
  val ACTION_CREATE_HOST = "_action_create_host"
  val ACTION_DELETE_HOST = "_action_delete_host"

  private val PATTERN_TEMPLATE = """template\(["']?([^)"']+)["']?\)""".r
  private val PATTERN_GROUP = """group\(["']?([^)"']+)["']?\)""".r
  private val PATTERN_JMX = "jmx_interface"

  def get(action: String)(host: String, ip: Option[String], port: Option[String],
    proxy: Option[String], metadata: Option[String]) = {
    checkNotEmpty(action, "action must be a none empty value")
    checkNotEmpty(host, "host must be a none empty value")

    action match {
      case ACTION_CREATE_HOST => getCreateHostAction(host, ip, port, proxy, metadata)
      case ACTION_DELETE_HOST => Some(DeleteHostAction(host))
      case _ => throw new Exception(s"Action $action not supportted")
    }
  }

  private def getCreateHostAction(host: String, ip: Option[String], port: Option[String],
    proxy: Option[String], metadata: Option[String]) = {
    if (ip == None || port == None || ip.get.equals("") || port.get.equals(""))
      throw new IllegalArgumentException(s"port or ip should not be emtpy, port=$port.get, ip=$ip.get")

    metadata match {
      case Some(data) => {
        val templates = PATTERN_TEMPLATE.findAllIn(data).matchData.map(_.subgroups(0)).toSet
        val groups = PATTERN_GROUP.findAllIn(data).matchData.map(_.subgroups(0)).toSet

        if (groups.size == 0)
          throw new Exception("None group assigned, you must assign at least one group for the host")

        var interfaces = Set(Interface("1", ip.get, port.get))
        if (data.contains(PATTERN_JMX)) {
          interfaces += Interface("4", ip.get, port.get)
        }
        Some(CreateHostAction(Host(host, proxy, templates, groups, interfaces)))
      }
      case None => {
        logger.warn(s"No metadata found for host $host, do nothing")
        None
      }
    }
  }

  private def checkNotEmpty(value: String, msg: String) {
    if (value == null || "".equals(value)) throw new IllegalArgumentException(msg)
  }
}

case class Interface(interface: String, ip: String, port: String)
case class Host(name: String, proxyName: Option[String], templates: Set[String], groups: Set[String], interfaces: Set[Interface])

abstract sealed class Action {
  def execute(): Unit
}

case class CreateHostAction(server: Host) extends Action with ZabbixRpcApi {
  override def execute() {
    val groups = server.groups map { getGroupIdByName(_) } collect { case Some(id) => s"""{"groupid": "${id}"}""" }
    if (groups.size == 0)
      throw new Exception("No group found on zabbix server, at must one valited group needed")
    val templates = server.templates map { getTemplateIdByName(_) } collect { case Some(id) => s"""{"templateid": "${id}"}""" }
    val proxyId = getProxyIdByName(server.proxyName.get)
    val interfaces = server.interfaces map {
      interface =>
        s"""{
          "type": ${interface.interface},
          "main": 1,
          "useip": 1,
          "ip": "${interface.ip}",
          "dns": "",
          "port": "${interface.port}"
        }"""
    }

    var request = Json.obj(
      "host" -> server.name,
      "interfaces" -> Json.parse(interfaces.mkString("[", ",", "]")),
      "groups" -> Json.parse(groups.mkString("[", ",", "]")),
      "inventory_mode" -> 1,
      "inventory" -> Json.obj(
        "notes" -> "Created by RPC API"))

    if (!proxyId.isEmpty) {
      request = request ++ Json.obj("proxy_hostid" -> proxyId.get)
    }
    if (!templates.isEmpty) {
      request = request ++ Json.obj("templates" -> Json.parse(templates.mkString("[", ",", "]")))
    }

    val createdHosts = (host.create(request) \ "hostids").as[JsArray].value
    logger.info(s"host ${createdHosts} created")
  }
}

/**
 * This action remove the host by the host name
 */
case class DeleteHostAction(server: String) extends Action with ZabbixRpcApi {
  override def execute() {
	getHostIdByName(server) match {
	  case Some(hostId) => host.delete(Json.parse(s"""["${hostId}"]"""), 300000)
	  case None => logger.warn(s"No host named ${server} found, do nothing")
	}
  }
}
