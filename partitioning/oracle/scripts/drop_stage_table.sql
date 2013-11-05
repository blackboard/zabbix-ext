set pagesize 1200 linesize 100 term off feedback off timing off heading off
spool &2
DROP TABLE &1;
spool off
EXIT;
