import AssemblyKeys._

scalaVersion := "2.10.3"

organization := "blackboard"

name := "rpc-api"

version := "0.1"

EclipseKeys.createSrc := EclipseCreateSrc.Default + EclipseCreateSrc.Resource

libraryDependencies ++= Seq(
  "org.scalaj" %% "scalaj-http" % "0.3.12",
  "org.slf4j" % "log4j-over-slf4j" % "1.7.2",
  "ch.qos.logback" % "logback-classic" % "1.0.7",
  "ch.qos.logback" % "logback-core" % "1.0.7",
  "com.typesafe.play" %% "play-json" % "2.2.1",
  "com.typesafe" % "config" % "1.0.2",
  "com.typesafe" %% "scalalogging-slf4j" % "1.0.1"
)

//tests
libraryDependencies ++= Seq(
  "junit" % "junit" % "4.10" % "test",
  "org.mockito" % "mockito-all" % "1.9.0" % "test",
  "org.specs2" %% "specs2" % "2.3.7" % "test"
)

parallelExecution in Test := false

resolvers += "typesafe releases" at "http://repo.typesafe.com/typesafe/releases"

assemblySettings
