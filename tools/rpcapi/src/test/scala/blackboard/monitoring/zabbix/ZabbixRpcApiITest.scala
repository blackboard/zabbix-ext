package blackboard.monitoring.zabbix

import org.junit.runner.RunWith
import org.specs2.runner.JUnitRunner
import play.api.libs.json._

@RunWith(classOf[JUnitRunner])
class ZabbixRpcApiITest extends ZabbixTest {
  private var testGroupId = ""
  private var testDeleteGroupId = ""
  private var testProxyId = ""
  private var testJmxTemplateId = ""
  private var testAgentTemplateId = ""
  private var hostid = ""

  override def setup() {
    testGroupId = createGroup(testGroup)
    testDeleteGroupId = createGroup(testDeleteGroup)
    testProxyId = createProxy(testProxy)
    testJmxTemplateId = createTemplate(testJmxTemplate, testGroupId)
    testAgentTemplateId = createTemplate(testAgentTemplate, testGroupId)
  }

  override def tearDown() {
    cleanHosts(testGroupId)
    cleanHosts(testDeleteGroupId)
    deleteTemplates(testJmxTemplateId, testAgentTemplateId)
    deleteGroups(testGroupId, testDeleteGroupId)
    deleteProxy(testProxyId)
  }

  "host" should {
    "host should not exists" in {
      getHostIdByName(hostname) must beNone
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

}

