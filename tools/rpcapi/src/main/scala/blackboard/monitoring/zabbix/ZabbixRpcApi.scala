package blackboard.monitoring.zabbix

import play.api.libs.json._
import play.api.libs.ws._
import scala.Dynamic
import scala.language.dynamics
import scala.concurrent.{ Future, Await }
import scala.concurrent.duration._
import scala.util.Random

trait ZabbixRpcApi {
  this: {
    def url: String
    def username: String
    def password: String
  } =>

  private val apiVersion = "2.0"
  private val requestTimeoutInSecond = 3
  private val responseTimeoutInSecond = 10

  val action = Category("action")
  val alert = Category("alert")
  val application = Category("application")
  val configuration = Category("configuration")
  val dhost = Category("dhost")
  val dservice = Category("dservice")
  val dcheck = Category("dcheck")
  val drule = Category("drule")
  val event = Category("event")
  val graph = Category("graph")
  val graphitem = Category("graphitem")
  val history = Category("history")
  val host = Category("host")
  val hostgroup = Category("hostgroup")
  val hostinterface = Category("hostinterface")
  val hostprototype = Category("hostprototype")
  val item = Category("item")
  val itemprototype = Category("itemprototype")
  val screen = Category("screen")
  val screenitem = Category("screenitem")
  val trigger = Category("trigger")
  val template = Category("template")

  private def doRequest(body: JsObject) = {
    implicit val context = scala.concurrent.ExecutionContext.Implicits.global
    val futureResult: Future[JsValue] = WS.url(url)
      .withHeaders(("Content-Type", "application/json-rpc"))
      .withRequestTimeout(requestTimeoutInSecond * 1000).post(body).map {
        response => response.json
      }

    val result = Await.ready(futureResult, Duration(responseTimeoutInSecond, SECONDS)).value.get.get

    (result \ "result").asOpt[JsValue] match {
      case Some(rtn) => rtn
      case None => {
        throw new Exception(Json.prettyPrint((result \ "error")))
      }
    }
  }

  private def auth = {
    val body = Json.obj(
      "jsonrpc" -> apiVersion,
      "method" -> "user.login",
      "params" -> Json.obj(
        "user" -> username,
        "password" -> password),
      "id" -> requestId)

    doRequest(body).as[String]
  }

  private def requestId = Random.nextLong()

  case class Category(category: String) extends Dynamic {
    def applyDynamic(method: String)(param: JsValue) = {
      val body = Json.obj(
        "jsonrpc" -> apiVersion,
        "method" -> s"$category.$method",
        "params" -> param,
        "auth" -> auth,
        "id" -> requestId)
      doRequest(body)
    }
  }
}