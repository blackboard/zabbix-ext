@echo off

IF %1.==. GOTO usage
IF %2.==. GOTO usage

setlocal enabledelayedexpansion 

cd /d %~dp0
rd /S/Q tmp
mkdir tmp
xcopy zabbix_agents_2.0.3.win\* tmp /E /Y
rem unzip -o zabbix_agents_2.0.3.win.zip -d tmp
echo Stop zabbix agent service
net stop "Zabbix Agent"
echo delete zabbix agent service
%1\zabbix_agentd.exe -c %1\zabbix_agentd.conf -d
rd /S/Q %1
mkdir %1

goto:%PROCESSOR_ARCHITECTURE:~-1%
:6
goto cp_32bit_agent
:4
goto cp_64bit_agent

:cp_32bit_agent
echo It's 32bit OS
xcopy tmp\bin\win32\* %1 /E /Y
goto process_agent

:cp_64bit_agent
echo It's 64bit OS
xcopy tmp\bin\win64\* %1 /E /Y
goto process_agent

:process_agent
for /f  %%a in  ('hostname') do set host_name=%%a
for /f "tokens=*" %%i in ('findstr /n .* tmp\zabbix_agentd.conf') do (
	set s=%%i
	set s=!s:REPLACE_SERVER=%2!
	set s=!s:INSTALL_PATH=%1!
	set s=!s:REPLACE_HOSTNAME=%host_name%!
	set s=!s:*:=! 
	echo.!s!>>%1/zabbix_agentd.conf
)
echo yes|cacls %1 /T /E /G administrator:F
echo yes|cacls %1 /T /E /G system:F

%1\zabbix_agentd.exe -c %1\zabbix_agentd.conf -i
%1\zabbix_agentd.exe -c %1\zabbix_agentd.conf -s

Rem Clean up
rd /S/Q tmp
goto end

:usage
echo Error in %0 - Invalid Argument Count
echo Syntax: %0 install_dir zabbix_server
echo Syntax Example: %0 d:\zbx w3x32s05-pv008

:end


