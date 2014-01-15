package blackboard.monitoring.zabbix

import org.junit.runner.RunWith
import org.specs2.runner.JUnitRunner
import org.specs2.mutable.Specification
import org.specs2.specification.Fragments
import org.specs2.specification.Step
import play.api.libs.json._
import com.typesafe.config.ConfigFactory

@RunWith(classOf[JUnitRunner])
class ActionFactoryTest extends Specification {
  "ActionFactory" should {
    "throw exception if null action passed in" in {
      ActionFactory.get(ActionArgument(null, "host", None, None, None, None)) must throwA[IllegalArgumentException]
      ActionFactory.get(ActionArgument("", "host", None, None, None, None)) must throwA[IllegalArgumentException]
      ActionFactory.get(ActionArgument("testAction", "host", None, None, None, None)) must throwA[Exception]
      ActionFactory.get(ActionArgument(ActionFactory.ACTION_DELETE_HOST, null, None, None, None, None)) must throwA[IllegalArgumentException]
      ActionFactory.get(ActionArgument(ActionFactory.ACTION_DELETE_HOST, "", None, None, None, None)) must throwA[IllegalArgumentException]
      ActionFactory.get(ActionArgument(ActionFactory.ACTION_CREATE_HOST, null, None, None, None, None)) must throwA[IllegalArgumentException]
      ActionFactory.get(ActionArgument(ActionFactory.ACTION_CREATE_HOST, "", None, None, None, None)) must throwA[IllegalArgumentException]
    }

    "throw exception if none ip passed in when creating host" in {
      ActionFactory.get(ActionArgument(ActionFactory.ACTION_CREATE_HOST, "host", None, None, None, None)) must throwA[IllegalArgumentException]
    }

    "get an instance of DeleteHostAction" in {
      val host = "host"
      val action = ActionFactory.get(ActionArgument(ActionFactory.ACTION_DELETE_HOST, host, None, None, None, None))
      action must beSome
      action.get must beAnInstanceOf[DeleteHostAction]
      action.get.asInstanceOf[DeleteHostAction].server must_== host
    }

    "get an instance of CreateHostAction" in {
      val host = "host"
      val ip = "9.9.9.9"
      val port = "15000"
      val proxy = "proxy1"
      val metadata = """template("template learn java"), template(template linux), jmx_interface, group(perf linux) group(continous)"""

      val action = ActionFactory.get(ActionArgument(ActionFactory.ACTION_CREATE_HOST, host, Some(ip), Some(port), Some(proxy), Some(metadata)))
      action must beSome
      action.get must beAnInstanceOf[CreateHostAction]
      val server = action.get.asInstanceOf[CreateHostAction].server
      server.name must_== host
      server.proxyName.get must_== proxy

      server.groups must have size (2)
      server.groups must contain("continous")
      server.groups must contain("perf linux")

      server.templates must have size (2)
      server.templates must contain("template learn java")
      server.templates must contain("template linux")

      server.interfaces must have size (2)
      server.interfaces must contain(Interface("1", ip, port))
      server.interfaces must contain(Interface("4", ip, ConfigFactory.load().getString("zabbix.jmx.port")))
    }

    "throw exception when no group in metadata" in {
      val host = "host"
      val ip = "9.9.9.9"
      val port = "15000"
      val proxy = "proxy1"
      val metadata = """template("template learn java"), template(template linux), jmx_interface"""

      ActionFactory.get(ActionArgument(ActionFactory.ACTION_CREATE_HOST, host, Some(ip), Some(port), Some(proxy), Some(metadata))) must throwA[Exception]
    }
  }
}