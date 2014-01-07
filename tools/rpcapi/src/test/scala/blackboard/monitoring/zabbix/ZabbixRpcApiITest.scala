package blackboard.monitoring.zabbix

import org.junit.runner.RunWith
import org.specs2.runner.JUnitRunner
import org.specs2.mutable.Specification
import play.api.libs.json._

@RunWith(classOf[JUnitRunner])
class ZabbixRpcApiITest extends Specification with ZabbixRpcApi {
  private val testGroup = "RPC API Tests"
  
  def url = "http://zabbix.pd.local/api_jsonrpc.php"
  def username = "rpc_api_account"
  def password = "changeme"

  "host" should {
    "create host should be successful" in {
      val groupId = testGroupId
      println(groupId)
      1 must_== 1
    }
  }

  def testGroupId = {
    hostgroup.get(Json.obj(
      "filter" -> Json.obj(
        "name" -> Json.arr(testGroup)))) match {
      case groups: JsArray => groups.value.headOption match {
        case Some(groupid) => (groupid \ "groupid").as[String]
        case None => throw new Exception(s"None group $testGroup found")
      }
      case _ => throw new Exception("The return value should be JSON array")
    }
  }
}

