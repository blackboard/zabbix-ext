BEGIN;
UPDATE zabbix_partition_arch
   SET archive_ind = :v_archive_ind
      ,archive_full_path_name = :v_archive_full_path
      ,dtmodified = localtimestamp
 WHERE archive_table_name = :v_arch_table_name;
INSERT INTO zabbix_partition_log ( 
 pk1, 
 zabbix_partition_pk1, 
 dtcreated, 
 message )
VALUES (
 nextval('zabbix_partition_log_seq'),
 :v_zabbix_partition_pk1,
 localtimestamp,
 'Archive old partion ' || :v_arch_table_name || ' to ' || :v_archive_full_path );  
COMMIT;
