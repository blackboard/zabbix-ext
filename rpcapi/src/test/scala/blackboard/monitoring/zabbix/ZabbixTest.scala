package blackboard.monitoring.zabbix

import org.specs2.mutable.Specification
import org.specs2.specification.Fragments
import org.specs2.specification.Step
import play.api.libs.json._

abstract class ZabbixTest extends Specification with ZabbixRpcApi {
  protected val testGroup = "RPC_API_TEST_GROUP_ORIGIN"
  protected val testDeleteGroup = "RPC_API_TEST_GROUP_TO_DELETE"
  protected val testProxy = "RPC_API_TEST_PROXY"
  protected val testJmxTemplate = "RPC_API_TEST_TEMPLATE_JMX"
  protected val testAgentTemplate = "RPC_API_TEST_TEMPLATE_AGENT"
  protected val hostname = "RPC_API_TEST_HOST"
  protected val hostip = "9.9.9.9"
  protected val port = "10050"

  /**
   * The examples here are executed one by one
   */
  sequential

  override def map(fs: => Fragments) = Step(setup) ^ fs ^ Step(tearDown)

  def setup()

  def tearDown()

  protected def createProxy(proxyName: String) = {
    (proxy.create(Json.obj("host" -> proxyName, "status" -> "5")) \ "proxyids").as[JsArray].value.head.as[String]
  }

  protected def deleteProxy(proxyId: String) {
    proxy.delete(Json.arr(proxyId))
  }

  protected def createTemplate(name: String, groupId: String) = {
    (template.create(Json.obj("host" -> name, "groups" -> Json.arr(Json.obj("groupid" -> groupId)))) \ "templateids").as[JsArray].value.head.as[String]
  }

  protected def deleteTemplates(ids: String*) {
    template.delete(Json.parse(ids.mkString("[", ",", "]")))
  }

  protected def deleteGroups(ids: String*) {
    hostgroup.delete(Json.parse(ids.mkString("[", ",", "]")))
  }

  protected def createGroup(group: String) = {
    (hostgroup.create(Json.obj("name" -> group)) \ "groupids").as[JsArray].value.head.as[String]
  }

  protected def cleanHosts(groupId: String) {
    host.get(Json.obj(
      "groupids" -> Json.arr(groupId))) match {
      case results: JsArray => {
        if (!results.value.isEmpty) {
          val hosts = results.value map { _ \ "hostid" }
          host.delete(Json.parse(hosts.mkString("[", ",", "]")), 300000)
        }
      }
      case _ => // do nothing when there is not host
    }
  }
}