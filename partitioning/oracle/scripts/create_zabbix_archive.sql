set pagesize 1200 linesize 100 term off feedback off timing off heading off
spool &1
SELECT 'ARCH:' || zabbix_partition_pk1 || ',' || archive_table_name
  FROM zabbix_partition_arch
 WHERE archive_ind = 'N'
 ORDER BY dtcreated;
spool off
exit;
