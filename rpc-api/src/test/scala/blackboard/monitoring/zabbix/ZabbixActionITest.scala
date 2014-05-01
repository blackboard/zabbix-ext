package blackboard.monitoring.zabbix

import org.junit.runner.RunWith
import org.specs2.runner.JUnitRunner
import play.api.libs.json._

@RunWith(classOf[JUnitRunner])
class ZabbixActionITest extends ZabbixTest {
  private var testGroupId = ""
  private var testJmxTemplateId = ""
  private var testAgentTemplateId = ""
  private var testProxyId = ""
  private var testHostId = ""

  override def setup() {
    testGroupId = createGroup(testGroup)
    testJmxTemplateId = createTemplate(testJmxTemplate, testGroupId)
    testAgentTemplateId = createTemplate(testAgentTemplate, testGroupId)
    testProxyId = createProxy(testProxy)
  }

  override def tearDown() {
    cleanHosts(testGroupId)
    deleteTemplates(testJmxTemplateId, testAgentTemplateId)
    deleteProxy(testProxyId)
    deleteGroups(testGroupId)
  }

  "Action" should {
    "create host with invalid group should throw exception" in {
      val cha = ActionFactory.get(ActionArgument(ActionFactory.ACTION_CREATE_HOST, hostname, Some(hostip),
        Some(port), Some(testProxy), Some("group(template learn linux)")))
      cha must beSome
      cha.get.execute must throwA[Exception]
    }

    "create host with 1 group, 2 template, 2 interfaces" in {
      val cha = ActionFactory.get(ActionArgument(ActionFactory.ACTION_CREATE_HOST, hostname, Some(hostip),
        Some(port), Some(testProxy), Some(s"group(${testGroup}), template(${testJmxTemplate}), template(${testAgentTemplate}), jmx_interface(7777)")))
      cha must beSome
      cha.get.execute()

      val createdHost = host.get(Json.obj(
        "output" -> "extend",
        "selectGroups" -> "extend",
        "selectInterfaces" -> "extend",
        "selectParentTemplates" -> "extend",
        "filter" -> Json.obj(
          "host" -> Json.arr(hostname))))
      createdHost must beAnInstanceOf[JsArray]
      val hosts = createdHost.as[JsArray].value
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
    
    "delete host should be successful" in {
      val cha = ActionFactory.get(ActionArgument(ActionFactory.ACTION_DELETE_HOST, hostname, None, None, None, None))
      cha must beSome
      cha.get.execute()
      
      val exists = host.exists(Json.obj("host" -> hostname)).as[Boolean]
      exists must_==false
    }
  }
}