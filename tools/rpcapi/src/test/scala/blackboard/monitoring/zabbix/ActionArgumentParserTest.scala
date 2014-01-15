package blackboard.monitoring.zabbix

import org.junit.runner.RunWith
import org.specs2.runner.JUnitRunner
import org.specs2.mutable.Specification
import org.apache.commons.cli.ParseException

@RunWith(classOf[JUnitRunner])
class ActionArgumentParserTest extends Specification {
  "ActionArgumentParser" should {
    "throw exception if action option is missing" in {
      ActionArgumentParser.parse(List("--host", "localhost")) must throwA[ParseException]
    }
    
    "throw exception if action option value is missing" in {
      ActionArgumentParser.parse(List("--action", "--host", "localhost")) must throwA[ParseException]
    }
    
    "throw exception if host option is missing" in {
      ActionArgumentParser.parse(List("--action", "create_host")) must throwA[ParseException]
    }

    "throw exception if host argument value is missing" in {
      ActionArgumentParser.parse(List("--host", "--action", "create_host")) must throwA[ParseException]
    }

    "get proper host and action" in {
      val host = "localhost"
      val arg = ActionArgumentParser.parse(List("--host", host, "--action", "create_host"))
      arg.host must_== host
      arg.action must_== "create_host"
    }

    "get proper ip" in {
      ActionArgumentParser.parse(List("--action", "create_host", "--host", "localhost")).ip must beNone
      ActionArgumentParser.parse(List("--action", "create_host", "--host", "localhost", "--ip")).ip must beNone
      ActionArgumentParser.parse(List("--action", "create_host", "--host", "localhost", "--ip", "192.168.0.1")).ip must beSome("192.168.0.1")
    }

    "get proper port" in {
      ActionArgumentParser.parse(List("--action", "create_host", "--host", "localhost")).port must beNone
      ActionArgumentParser.parse(List("--action", "create_host", "--host", "localhost", "--port")).port must beNone
      ActionArgumentParser.parse(List("--action", "create_host", "--host", "localhost", "--port", "8899")).port must beSome("8899")
    }

    "get proper proxy" in {
      ActionArgumentParser.parse(List("--action", "create_host", "--host", "localhost")).proxy must beNone
      ActionArgumentParser.parse(List("--action", "create_host", "--host", "localhost", "--proxy")).proxy must beNone
      ActionArgumentParser.parse(List("--action", "create_host", "--host", "localhost", "--proxy", "")).proxy must beNone
      ActionArgumentParser.parse(List("--action", "create_host", "--action", "create_host", "--host", "localhost", "--proxy", "zabbix.proxy.pd")).proxy must beSome("zabbix.proxy.pd")
    }

    "get proper metadata" in {
      val metadata = "jmx_interface,template(Template Learn Linux),group(Perf Linux),template(Template Learn Java)"
      val metadata1 = """jmx_interface,template("Template Learn Linux"), group(Perf Linux),template("Template Learn Java")"""
      ActionArgumentParser.parse(List("--action", "create_host", "--host", "localhost")).metadata must beNone
      ActionArgumentParser.parse(List("--action", "create_host", "--host", "localhost", "--metadata")).metadata must beNone
      ActionArgumentParser.parse(List("--action", "create_host", "--host", "localhost", "--metadata", metadata)).metadata must beSome(metadata)
      ActionArgumentParser.parse(List("--action", "create_host", "--host", "localhost", "--metadata", metadata1)).metadata must beSome(metadata1)
    }
  }
}