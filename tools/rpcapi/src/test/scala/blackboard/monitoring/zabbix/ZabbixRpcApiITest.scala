package blackboard.monitoring.zabbix

import org.junit.runner.RunWith
import org.specs2.runner.JUnitRunner
import org.specs2.mutable.Specification
import org.specs2.specification.Fragments
import org.specs2.specification.Step
import play.api.libs.json._
import com.typesafe.config.ConfigFactory

@RunWith(classOf[JUnitRunner])
class ZabbixRpcApiITest extends Specification with ZabbixRpcApi {
  private val testGroup = "RPC_API_TEST_GROUP_ORIGIN"
  private val testDeleteGroup = "RPC_API_TEST_GROUP_TO_DELETE"
  private val testProxy = "RPC_API_TEST_PROXY"
  private val testJmxTemplate = "RPC_API_TEST_TEMPLATE_JMX"
  private val testAgentTemplate = "RPC_API_TEST_TEMPLATE_AGENT"
  private val hostname = "RPC_API_TEST_HOST"
  private val hostip = "9.9.9.9"
  private val port = "10050"

  private var testGroupId = ""
  private var testDeleteGroupId = ""
  private var testProxyId = ""
  private var testJmxTemplateId = ""
  private var testAgentTemplateId = ""
  private var hostid = ""

  /**
   * The examples here are executed one by one
   */
  sequential

  override def map(fs: => Fragments) = Step(setup) ^ fs ^ Step(tearDown)

  def setup() {
    testGroupId = createGroup(testGroup)
    testDeleteGroupId = createGroup(testDeleteGroup)
    createProxy()
    testJmxTemplateId = createTemplate(testJmxTemplate, testGroupId)
    testAgentTemplateId = createTemplate(testAgentTemplate, testGroupId)
  }

  def tearDown() {
    cleanHosts(testGroupId)
    cleanHosts(testDeleteGroupId)
    deleteGroups()
    deleteProxy()
    deleteTemplates()
  }

  "host" should {
    "host should not exists" in {
      getHostIdByName(hostname) must throwA[Exception]
    }

    "create host should be successful" in {
      val createdHosts = host.create(Json.obj(
        "host" -> hostname,
        "interfaces" -> Json.arr(
          Json.obj(
            "type" -> 1,
            "main" -> 1,
            "useip" -> 1,
            "ip" -> hostip,
            "dns" -> "",
            "port" -> port),
          Json.obj(
            "type" -> 4,
            "main" -> 1,
            "useip" -> 1,
            "ip" -> hostip,
            "dns" -> "",
            "port" -> 5432)),
        "groups" -> Json.arr(Json.obj(
          "groupid" -> testGroupId)),
        "templates" -> Json.arr(
          Json.obj(
            "templateid" -> testJmxTemplateId),
          Json.obj(
            "templateid" -> testAgentTemplateId)),
        "inventory_mode" -> 1,
        "proxy_hostid" -> testProxyId,
        "inventory" -> Json.obj(
          "notes" -> "Created by RPC API")))
      createdHosts \ "hostids" must beAnInstanceOf[JsArray]
      (createdHosts \ "hostids").as[JsArray].value must have size (1)
      hostid = (createdHosts \ "hostids").as[JsArray].value.head.as[String]
      hostid must not be empty
    }

    "created host parameter should be expected" in {
      val createdHosts = host.get(Json.obj(
        "output" -> Json.arr("hostid"),
        "hostids" -> Json.arr(hostid),
        "selectGroups" -> "extend",
        "selectInterfaces" -> "extend",
        "selectParentTemplates" -> "extend"))
      createdHosts must beAnInstanceOf[JsArray]
      val hosts = createdHosts.as[JsArray].value
      hosts must have size (1)

      //check group
      (hosts.head \ "groups") must beAnInstanceOf[JsArray]
      (hosts.head \ "groups").as[JsArray].value must have size (1)
      ((hosts.head \ "groups").as[JsArray].value.head \ "name").as[String] must_== testGroup

      //check interface
      (hosts.head \ "interfaces") must beAnInstanceOf[JsArray]
      (hosts.head \ "interfaces").as[JsArray].value must have size (2)

      //check template
      (hosts.head \ "parentTemplates") must beAnInstanceOf[JsArray]
      (hosts.head \ "parentTemplates").as[JsArray].value must have size (2)
    }

    "move host to another group and disable it" in {
      host.update(Json.obj(
        "hostid" -> hostid,
        "status" -> 1,
        "groups" -> Json.arr(Json.obj("groupid" -> testDeleteGroupId))))
      1 must_== 1
    }

    "updated host parameter should be expected" in {
      val createdHosts = host.get(Json.obj(
        "output" -> "extend",
        "hostids" -> Json.arr(hostid),
        "selectGroups" -> "extend",
        "selectInterfaces" -> "extend",
        "selectParentTemplates" -> "extend"))
      createdHosts must beAnInstanceOf[JsArray]
      val hosts = createdHosts.as[JsArray].value
      hosts must have size (1)

      //check group
      (hosts.head \ "groups") must beAnInstanceOf[JsArray]
      (hosts.head \ "groups").as[JsArray].value must have size (1)
      ((hosts.head \ "groups").as[JsArray].value.head \ "name").as[String] must_== testDeleteGroup

      //check status
      (hosts.head \ "status").as[String] must_== "1"
    }
  }

  private def createProxy() {
    testProxyId = (proxy.create(Json.obj("host" -> testProxy, "status" -> "5")) \ "proxyids").as[JsArray].value.head.as[String]
  }

  private def deleteProxy() {
    proxy.delete(Json.arr(testProxyId))
  }

  private def createTemplate(name: String, groupId: String) = {
    (template.create(Json.obj("host" -> name, "groups" -> groupId)) \ "templateids").as[JsArray].value.head.as[String]
  }

  private def deleteTemplates() {
    template.delete(Json.arr(testJmxTemplateId, testAgentTemplateId))
  }

  private def deleteGroups() {
    hostgroup.delete(Json.arr(testGroupId, testDeleteGroupId))
  }

  private def createGroup(group: String) = {
    (hostgroup.create(Json.obj("name" -> group)) \ "groupids").as[JsArray].value.head.as[String]
  }

  private def cleanHosts(groupId: String) {
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

