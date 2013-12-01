set pagesize 1200 linesize 100 term off feedback off timing off heading off
spool &5
UPDATE zabbix_partition_arch
   SET archive_ind = '&1'
      ,archive_full_path_name = '&2'
      ,dtmodified = SYSDATE
 WHERE archive_table_name = '&3';
INSERT INTO zabbix_partition_log ( 
 pk1, 
 zabbix_partition_pk1, 
 dtcreated, 
 message )
VALUES (
 zabbix_partition_log_seq.nextval,
 '&4',
 SYSDATE,
 'Archive old partion ' || '&3' || ' to ' || '&2');  
COMMIT;
spool off
EXIT;
