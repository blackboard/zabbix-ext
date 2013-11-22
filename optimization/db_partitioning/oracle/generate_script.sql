set serveroutput on size 100000 pagesize 1200 linesize 100 term off feedback off timing off heading off
spool &1
EXEC zabbix_maintaince.convert_to_partition( p_forscript=> 'Y' );
EXIT;
spool off
