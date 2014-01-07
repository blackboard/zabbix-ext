package blackboard.monitoring.zabbix

import play.api.libs.json._
import scalaj.http._
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
  private val timeout = 10000
  private val HTTP_OK = 200

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
    val options = List(HttpOptions.readTimeout(10000))
    val headers = ("Content-Type", "application/json-rpc")
    val request = Http.postData(url, Json.stringify(body)).headers(headers).options(options)

    request.responseCode match {
      case HTTP_OK => {
        val result = Json.parse(request.asString)
        (result \ "result").asOpt[JsValue] match {
          case Some(rtn) => rtn
          case None => {
            throw new Exception(Json.prettyPrint((result \ "error")))
          }
        }
      }
      case status: Int => throw new Exception(s"Wrong response HTTP status code $status")
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