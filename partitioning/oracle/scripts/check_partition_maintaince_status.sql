set pagesize 1200 linesize 100 term off feedback off timing off heading off
spool &1
SELECT CASE WHEN COUNT(1) > 0 THEN 'FAILED' ELSE 'SUCCESSFUL' END 
  FROM zabbix_partition
 WHERE status = 'F';
spool off
exit;
