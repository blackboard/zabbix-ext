package blackboard.monitoring.zabbix

import org.junit.runner.RunWith
import org.specs2.runner.JUnitRunner
import org.specs2.mutable.Specification
import org.specs2.specification.Fragments
import org.specs2.specification.Step
import play.api.libs.json._
import com.typesafe.config.ConfigFactory

@RunWith(classOf[JUnitRunner])
class ZabbixRpcApiITest extends Specification with ZabbixCommonOps {
  override lazy val debug = true
  private val testGroup = ConfigFactory.load.getString("zabbix.test.group")

  sequential

  override def map(fs: => Fragments) = fs ^ Step(cleanHosts)

  def cleanHosts {
    /*
    val groupId = getGroupIdByName(testGroup)
    host.get(Json.obj(
      "groupids" -> Json.arr(groupId))) match {
      case results: JsArray => {
        val hosts = results.value map { _ \ "hostid" }
        host.delete(Json.parse(hosts.mkString("[", ",", "]")))
      }
      case _ => // do nothing when there is not host
    }
    */
  }

  "host" should {
    val hostname = "RPC_API_TEST_HOST"
    val hostip = "9.9.9.9"
    val port = "10050"

    "host should not exists" in {
      getHostIdByName(hostname) must throwA[Exception]
    }

    "create host should be successful" in {
      val groupId = getGroupIdByName(testGroup)
      val createdHost = host.create(Json.obj(
        "host" -> hostname,
        "interfaces" -> Json.arr(Json.obj(
          "type" -> 1,
          "main" -> 1,
          "useip" -> 1,
          "ip" -> hostip,
          "dns" -> "",
          "port" -> port)),
        "groups" -> Json.arr(Json.obj(
          "groupid" -> groupId)),
        "inventory_mode" -> 1,
        "inventory" -> Json.obj(
          "notes" -> "Created by RPC API")))

      1 must_== 1
    }
  }
}

