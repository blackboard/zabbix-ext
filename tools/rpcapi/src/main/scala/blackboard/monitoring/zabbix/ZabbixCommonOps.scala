package blackboard.monitoring.zabbix

import play.api.libs.json._

trait ZabbixCommonOps extends ZabbixRpcApi {
  def getGroupIdByName(name: String) = {
    val result = hostgroup.get(Json.obj(
      "filter" -> Json.obj(
        "name" -> Json.arr(name))))
    extractUniqueId("groupid", result)
  }

  def getHostIdByName(hostname: String) = {
    val result = host.get(Json.obj(
      "filter" -> Json.obj(
        "host" -> Json.arr(hostname))))
    extractUniqueId("hostid", result)
  }

  def getProxyIdByName(proxyName: String) = {
    val result = proxy.get(Json.obj(
      "filter" -> Json.obj(
        "host" -> Json.arr(proxyName))))
    extractUniqueId("proxyid", result)
  }

  def getTemplateIdByName(templateName: String) = {
    val result = template.get(Json.obj(
      "filter" -> Json.obj(
        "host" -> Json.arr(templateName))))
    extractUniqueId("templateid", result)
  }
}