import AssemblyKeys._

scalaVersion := "2.10.3"

organization := "blackboard"

name := "rpc-api"

version := "0.1"

EclipseKeys.createSrc := EclipseCreateSrc.Default + EclipseCreateSrc.Resource

libraryDependencies ++= Seq(
  "com.typesafe.play" %% "play-json" % "2.2.1",
  "org.scalaj" %% "scalaj-http" % "0.3.12",
  "com.typesafe" % "config" % "1.0.2"
)

parallelExecution in Test := false

//tests
libraryDependencies ++= Seq(
  "junit" % "junit" % "4.10" % "test",
  "org.mockito" % "mockito-all" % "1.9.0" % "test",
  "org.specs2" %% "specs2" % "2.3.7" % "test"
)

resolvers += "typesafe releases" at "http://repo.typesafe.com/typesafe/releases"

assemblySettings
