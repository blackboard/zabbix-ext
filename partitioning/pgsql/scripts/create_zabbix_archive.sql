SELECT 'ARCH:' || zabbix_partition_pk1 || ',' || archive_table_name
  FROM zabbix_partition_arch
 WHERE archive_ind = 'N'
 ORDER BY dtcreated;
