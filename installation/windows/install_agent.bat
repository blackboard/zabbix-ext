@echo off

IF %1.==. GOTO usage
IF %2.==. GOTO usage

setlocal enabledelayedexpansion 

set zabbix_source=zabbix_agents_2.2.0.win

cd /d %~dp0
echo Stop zabbix agent service
net stop "Zabbix Agent"
echo delete zabbix agent service
sc delete "Zabbix Agent"
rd /S/Q %1
mkdir %1

goto:%PROCESSOR_ARCHITECTURE:~-1%
:6
goto cp_32bit_agent
:4
goto cp_64bit_agent

:cp_32bit_agent
echo It's 32bit OS
xcopy %zabbix_source%\bin\win32\* %1 /E /Y
goto process_agent

:cp_64bit_agent
echo It's 64bit OS
xcopy %zabbix_source%\bin\win64\* %1 /E /Y
goto process_agent

:process_agent
for /f %%a in  ('hostname') do set host_name=%%a
for /f "tokens=1 delims=," %%a in (%2) do set active_server=%%a
for /f "tokens=*" %%i in ('findstr /n .* %zabbix_source%\zabbix_agentd.conf') do (
	set s=%%i
	set s=!s:REPLACE_SERVER=%~2!
	set s=!s:INSTALL_PATH=%~1!
  set s=!s:METADATA_REPLACE=%~3!
  set s=!s:REPLACE_ACTIVE_SERVER=%active_server%!
	set s=!s:REPLACE_HOSTNAME=%host_name%!
	set s=!s:*:=! 
	echo.!s!>>%1/zabbix_agentd.conf
)
echo yes|cacls %1 /T /E /G administrator:F
echo yes|cacls %1 /T /E /G system:F

%1\zabbix_agentd.exe -c %1\zabbix_agentd.conf -i
%1\zabbix_agentd.exe -c %1\zabbix_agentd.conf -s
goto end

:usage
echo Error in %0 - Invalid Argument Count
echo Syntax: %0 install_dir zabbix_server
echo Syntax Example: %0 d:\zbx w3x32s05-pv008 metadata

:end


