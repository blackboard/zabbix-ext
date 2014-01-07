package blackboard.monitoring.zabbix

import scala.Dynamic
import scala.language.dynamics
import scala.util.Random
import com.typesafe.config.ConfigFactory
import scalaj.http._
import play.api.libs.json._
import java.util.concurrent.TimeUnit

trait ZabbixRpcApi {
  val config = ConfigFactory.load
  lazy val debug = false

  var authKey: Option[String] = None

  def url = config.getString("zabbix.rpcapi")
  def username = config.getString("zabbix.username")
  def password = config.getString("zabbix.password")

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
  val proxy = Category("proxy")
  val screen = Category("screen")
  val screenitem = Category("screenitem")
  val trigger = Category("trigger")
  val template = Category("template")

  def extractUniqueId(field: String, result: JsValue) = {
    result match {
      case items: JsArray => items.value.headOption match {
        case Some(item) => (item \ field).as[String]
        case None => throw new Exception(s"No $field found")
      }
      case _ => throw new Exception("Only JSON Array supported but the result is not")
    }
  }

  def doRequest(body: JsValue) = {
    val options = List(HttpOptions.readTimeout(10000))
    val headers = ("Content-Type", "application/json-rpc")
    val request = Http.postData(url, Json.stringify(body)).headers(headers).options(options)

    if (debug) {
      println("Request:\n" + Json.prettyPrint(body))
    }

    val (responseCode, headersMap, resultString) = request.asHeadersAndParse(Http.readString)
    
    responseCode match {
      case HTTP_OK => {
        val result = Json.parse(resultString)
        if (debug) {
          println("Response:\n" + Json.prettyPrint(result))
        }
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

  def auth = {
    authKey match {
      case Some(key) => key
      case None => {
        val body = Json.obj(
          "jsonrpc" -> apiVersion,
          "method" -> "user.login",
          "params" -> Json.obj(
            "user" -> username,
            "password" -> password),
          "id" -> requestId)
        authKey = Some(doRequest(body).as[String])
        authKey.get
      }
    }
  }

  private def requestId = Random.nextInt(Int.MaxValue)

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