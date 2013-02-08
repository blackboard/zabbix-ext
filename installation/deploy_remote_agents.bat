@echo off

set REMOTE_TMP_DIR=c$\zabbix_installation
set REMOTE_ZABBIX_DIR=c:\zabbix_installation
set LOG_FILE=deploy.log

cd /d %~dp0

if not "%1" == "-s" goto usage
shift
set SERVER=%1
shift
if not "%1" == "-u" goto usage
shift
set USER=%1
shift
if not "%1" == "-p" goto usage
shift
set PASSWORD=%1
shift
if not "%1" == "-d" goto usage
shift
set DATA_FILE=%1
if not exist %DATA_FILE% goto usage
shift

echo deploy result: > %LOG_FILE%

for /f "tokens=1,2 delims=, " %%i in (%DATA_FILE%) do (
set host=%%i
set install_dir=%%j

echo==================================================================="
echo install zabbix agent on %%i:/%%j
echo copy file to \\%%i\%REMOTE_TMP_DIR%
xcopy /Y/E/I windows \\%%i\%REMOTE_TMP_DIR%\windows

echo install agent on \\%%i %%j
tools\PsExec.exe \\%%i -u %USER% -p %PASSWORD% %REMOTE_ZABBIX_DIR%\windows\install_agent.bat %%j %SERVER%

if ERRORLEVEL 0 echo deploy agent on %%i successful >> %LOG_FILE%
if not ERRORLEVEL 0 echo deploy agent on %%i faile >> %LOG_FILE%
)
goto end

:usage
echo "usage: %0 -s server -u username -p password -d datafile"
echo "for example: $0 -s zabbix.pd.local -u root -p pass -d zabbix_list.data"

:end