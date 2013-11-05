CREATE TABLE zabbix_partition (
  pk1 NUMBER NOT NULL PRIMARY KEY,
  table_name VARCHAR2(30) NOT NULL,
  partition_key VARCHAR2(30) NOT NULL,
  reserve_months INTEGER DEFAULT 12 NOT NULL,
  prebuild_months INTEGER DEFAULT 3 NOT NULL,
  last_added_partition VARCHAR2(30) NOT NULL,
  last_removed_partition VARCHAR2(30) NOT NULL,
  status CHAR(2) DEFAULT 'U' NOT NULL,
  dtcreated DATE NOT NULL,
  dtmodified DATE NOT NULL
)
/
CREATE TABLE zabbix_partition_log (
  pk1 NUMBER NOT NULL PRIMARY KEY,
  zabbix_partition_pk1 INTEGER NOT NULL,
  dtcreated DATE NOT NULL,
  message VARCHAR2(2000)
)
/
CREATE TABLE zabbix_partition_arch (
  pk1 NUMBER NOT NULL PRIMARY KEY,
  zabbix_partition_pk1 INTEGER NOT NULL,
  table_name VARCHAR2(30) NOT NULL,
  partition_name VARCHAR2(30) NOT NULL,
  archive_table_name VARCHAR2(30) NOT NULL,
  archive_ind CHAR(1) DEFAULT 'N' NOT NULL ,
  dtcreated DATE NOT NULL,
  dtmodified DATE NOT NULL, 
  archive_full_path_name VARCHAR2(1000) 
)
/
CREATE TABLE zabbix_housekeeper (
  pk1 NUMBER NOT NULL PRIMARY KEY,
  table_name VARCHAR2(30) NOT NULL,
  del_cond_col_name VARCHAR2(30) NOT NULL, 
  reserve_days INTEGER DEFAULT 365 NOT NULL,
  status CHAR(1) DEFAULT 'U' NOT NULL,
    -- 'U': No maintaince
    -- 'F': Maintaince Failed
    -- 'S': Maintaince Success 
  dtcreated DATE NOT NULL,
  dtmodified DATE NOT NULL
)
/
CREATE SEQUENCE zabbix_partition_seq
/
CREATE SEQUENCE zabbix_partition_log_seq
/
CREATE SEQUENCE zabbix_partition_arch_seq
/
CREATE SEQUENCE zabbix_housekeeper_seq
/
CREATE UNIQUE INDEX zabbix_partition_ak1 ON zabbix_partition ( table_name )
/
CREATE INDEX zabbix_partition_log_ie1 ON zabbix_partition_log ( zabbix_partition_pk1 )
/
CREATE INDEX zabbix_partition_log_ie2 ON zabbix_partition_log ( dtcreated )
/
CREATE INDEX zabbix_partition_arch_ie1 ON zabbix_partition_arch ( zabbix_partition_pk1 )
/
CREATE INDEX zabbix_partition_arch_ie2 ON zabbix_partition_arch ( dtcreated )
/
CREATE UNIQUE INDEX zabbix_housekeeper_ak1 ON zabbix_housekeeper ( table_name )
/
CREATE OR REPLACE PACKAGE zabbix_maintaince
AUTHID CURRENT_USER
IS
  FUNCTION oracle_to_unix ( p_oracle_date DATE ) RETURN NUMBER;
  FUNCTION unix_to_oracle ( p_unix_time NUMBER ) RETURN DATE;
  FUNCTION has_table ( p_table_name VARCHAR2 ) RETURN CHAR;
  FUNCTION has_column ( p_table_name VARCHAR2, p_partition_key VARCHAR2 ) RETURN CHAR;
  FUNCTION is_partition_table ( p_table_name VARCHAR2 ) RETURN CHAR;
  FUNCTION is_housekeeper_table ( p_table_name VARCHAR2 ) RETURN CHAR;
  FUNCTION get_tablespace_name ( p_name VARCHAR2, p_type VARCHAR2 ) RETURN VARCHAR2;
  PROCEDURE register_partition_table (
    p_table_name VARCHAR2,
    p_partition_key VARCHAR2,
    p_reserve_months INTEGER,
    p_prebuild_months INTEGER );
  PROCEDURE unregister_partition_table ( p_table_name VARCHAR2 );
  PROCEDURE register_housekeeper_table (
    p_table_name VARCHAR2,
    p_del_cond_col_name VARCHAR2,
    p_reserve_days INTEGER := 365 );
  PROCEDURE unregister_housekeeper_table ( p_table_name VARCHAR2 );  
  PROCEDURE add_partitions ( p_table_name VARCHAR2 := NULL );
  PROCEDURE remove_partitions ( p_table_name VARCHAR2 := NULL );
  PROCEDURE output_script ( p_script VARCHAR2 );
  PROCEDURE execute_sql (
    p_sql VARCHAR2,
    p_pk1 NUMBER,
    p_status CHAR,
    p_msg VARCHAR,
    p_forscript CHAR ); 
  PROCEDURE write_log ( p_pk1 NUMBER, p_msg VARCHAR2 );
  PROCEDURE change_status (
    p_pk1 NUMBER,
    p_status CHAR,
    p_msg VARCHAR2,
    p_forscript CHAR
  );
  PROCEDURE housekeeper_cleanup ( p_table_name VARCHAR2 := NULL );
  PROCEDURE convert_to_partition ( p_tablename VARCHAR2 := NULL, p_forscript CHAR := 'Y' );
END zabbix_maintaince;
/
CREATE OR REPLACE PACKAGE BODY zabbix_maintaince
IS
  FUNCTION oracle_to_unix ( p_oracle_date DATE ) 
  RETURN NUMBER
  IS
  BEGIN
    RETURN( (p_oracle_date - TO_DATE('19700101','yyyymmdd'))*86400 - TO_NUMBER(SUBSTR(TZ_OFFSET(sessiontimezone),1,3))*3600);
  END oracle_to_unix;
  
  FUNCTION unix_to_oracle ( p_unix_time NUMBER ) 
  RETURN DATE
  IS
  BEGIN
    RETURN(TO_DATE('19700101','yyyymmdd') + p_unix_time/86400 +TO_NUMBER(SUBSTR(TZ_OFFSET(sessiontimezone),1,3))/24);
  END unix_to_oracle;
  
  FUNCTION has_table ( p_table_name VARCHAR2 )
  RETURN CHAR
  IS
    v_count INTEGER; 
  BEGIN
  	-- Check if the table exists
  	SELECT COUNT(1) INTO v_count FROM user_tables WHERE table_name = UPPER( p_table_name );
  	IF ( v_count = 0 ) THEN
  	  RETURN 'N';
  	ELSE
  	  RETURN 'Y';
    END IF;     
  END has_table;
  
  FUNCTION has_column ( p_table_name VARCHAR2, p_partition_key VARCHAR2 )
  RETURN CHAR
  IS
    v_count INTEGER; 
  BEGIN
  	-- Check if the partition key exists
  	SELECT COUNT(1) INTO v_count FROM user_tab_columns WHERE table_name = UPPER( p_table_name ) AND column_name = UPPER( p_partition_key );
  	IF ( v_count = 0 ) THEN
  	  RETURN 'N';
  	ELSE
  	  RETURN 'Y';
    END IF;     
  END has_column;
  
  FUNCTION is_partition_table ( p_table_name VARCHAR2 )
  RETURN CHAR
  IS
    v_count INTEGER; 
  BEGIN
  	-- Check if it is a partition table
  	SELECT COUNT(1) INTO v_count FROM zabbix_partition WHERE table_name = UPPER( p_table_name );
  	IF ( v_count = 0 ) THEN
  	  RETURN 'N';
  	ELSE
  	  RETURN 'Y';
    END IF;     
  END is_partition_table;
  
  FUNCTION is_housekeeper_table ( p_table_name VARCHAR2 )
  RETURN CHAR
  IS
    v_count INTEGER; 
  BEGIN
  	-- Check if it is a housekeeper table
  	SELECT COUNT(1) INTO v_count FROM zabbix_housekeeper WHERE table_name = UPPER( p_table_name );
  	IF ( v_count = 0 ) THEN
  	  RETURN 'N';
  	ELSE
  	  RETURN 'Y';
    END IF;     
  END is_housekeeper_table;
  
  FUNCTION get_tablespace_name ( p_name VARCHAR2, p_type VARCHAR2 ) 
  RETURN VARCHAR2
  IS
    v_tablespace_name VARCHAR2( 30 );
  BEGIN
  	IF ( p_type = 'TABLE' ) THEN
  	 	SELECT tablespace_name INTO v_tablespace_name FROM user_tables WHERE table_name = p_name;
  	ELSIF ( p_type = 'INDEX' ) THEN
  	 	SELECT tablespace_name INTO v_tablespace_name FROM user_indexes WHERE index_name = p_name;
  	ELSE
  	  v_tablespace_name := '';
  	END IF;
  	RETURN v_tablespace_name; 
  END get_tablespace_name;

  PROCEDURE output_script (
    p_script VARCHAR2
  )
  IS 
    c_crlf CONSTANT VARCHAR2(20) := CHR(13) || CHR(10);
    c_execute_char CONSTANT VARCHAR2(20) := c_crlf || '/' || c_crlf;
    v_start INTEGER;
    v_end INTEGER; 
    v_len INTEGER;
  BEGIN
    DBMS_OUTPUT.ENABLE( 100000 );
    
    v_len := length( p_script );
    v_start := 1;
    v_end := INSTR( p_script, c_crlf, v_start );
    WHILE ( 1 = 1 )
    LOOP
      DBMS_OUTPUT.PUT_LINE( SUBSTR( p_script, v_start, v_end - v_start ) );
      
      v_start := v_end + 2;
      v_end := INSTR( p_script, c_crlf, v_start );  

      EXIT WHEN v_start > v_len;
    END LOOP;  	
  END output_script;

  PROCEDURE execute_sql (
    p_sql VARCHAR2,
    p_pk1 NUMBER,
    p_status CHAR,
    p_msg VARCHAR,
    p_forscript CHAR
  ) 
  IS
  BEGIN
  	IF ( p_forscript = 'N' ) THEN
  	  write_log( p_pk1, p_sql );
      EXECUTE IMMEDIATE p_sql;
      IF ( p_status IS NOT NULL ) THEN
        change_status ( p_pk1, p_status , p_msg, p_forscript );
      END IF;
    END IF;      
  END execute_sql;

  PROCEDURE write_log ( 
    p_pk1 NUMBER,
    p_msg VARCHAR2
  )
  IS
  BEGIN
    INSERT INTO zabbix_partition_log ( 
      pk1, 
      zabbix_partition_pk1, 
      dtcreated, 
      message 
    )
    VALUES (
      zabbix_partition_log_seq.nextval,
      p_pk1,
      SYSDATE,
      p_msg
    );  
    COMMIT;   	
    DBMS_OUTPUT.PUT_LINE( p_msg );
  END write_log;

  PROCEDURE change_status (
    p_pk1 NUMBER,
    p_status CHAR,
    p_msg VARCHAR2,
    p_forscript CHAR
  )
  IS
  BEGIN
  	IF ( p_forscript = 'N' ) THEN
      UPDATE zabbix_partition 
         SET status = p_status
       WHERE pk1 = p_pk1;
     
      write_log( p_pk1, p_msg );
    END IF;
  END change_status;

  PROCEDURE unregister_partition_table ( p_table_name VARCHAR2 )
  IS
    v_pk1 NUMBER;
    e_unregister EXCEPTION;  
  BEGIN
    IF ( is_partition_table( p_table_name ) = 'N' ) THEN
      RAISE e_unregister;
    END IF;
  	
  	DELETE FROM zabbix_partition_arch WHERE zabbix_partition_pk1 = v_pk1;
  	COMMIT;
  	DELETE FROM zabbix_partition_log WHERE zabbix_partition_pk1 = v_pk1;
  	COMMIT;
  	DELETE FROM zabbix_partition WHERE pk1 = v_pk1;
  	COMMIT;
    DBMS_OUTPUT.PUT_LINE( 'Unregister the table ( ' || p_table_name || ' ) Successfully.' );
  EXCEPTION
    WHEN e_unregister THEN
      DBMS_OUTPUT.PUT_LINE( 'Unregister Failed: the table ( ' || p_table_name || ' ) doesn''t exist.' );
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE( 'Unregister Failed.' );
      RAISE;
  END unregister_partition_table;
  
  PROCEDURE register_partition_table (
    p_table_name VARCHAR2,
    p_partition_key VARCHAR2,
    p_reserve_months INTEGER,
    p_prebuild_months INTEGER )
  IS 
    c_default_reserve_months CONSTANT INTEGER := 3;
    c_default_prebuild_months CONSTANT INTEGER := 3;
    
    v_zabbix_partition_pk1 NUMBER;
    v_min_value INTEGER;
    v_max_value INTEGER;
    v_last_removed_partition VARCHAR2(30);
    v_last_added_partition VARCHAR2(30);
    v_reserve_months INTEGER;
    v_prebuild_months INTEGER;
    v_sql VARCHAR2(100);  
    v_count INTEGER; 
    e_table_not_exist EXCEPTION;
    e_partition_key_not_exist EXCEPTION;
    e_dup_register EXCEPTION;
    e_housekeeper_register EXCEPTION;
  BEGIN
  	IF ( is_partition_table( p_table_name ) = 'Y' ) THEN
  	  RAISE e_dup_register;
    END IF;

  	IF ( is_housekeeper_table( p_table_name ) = 'Y' ) THEN
  	  RAISE e_housekeeper_register;
    END IF;

  	IF ( has_table( p_table_name ) = 'N' ) THEN
  	  RAISE e_table_not_exist;
    END IF;
    
  	IF ( has_column ( p_table_name, p_partition_key ) = 'N' ) THEN
  	  RAISE e_partition_key_not_exist;
    END IF;

  	v_sql := 'SELECT MIN( ' || p_partition_key || ' ) FROM ' || p_table_name;
    EXECUTE IMMEDIATE v_sql INTO v_min_value;
    
    IF ( v_min_value IS NULL ) THEN
      v_min_value := oracle_to_unix ( SYSDATE ); 
    END IF;
    v_max_value := oracle_to_unix ( SYSDATE );
    
    v_last_removed_partition := 'M' || TO_CHAR( ADD_MONTHS( unix_to_oracle( v_min_value ), -1 ), 'YYYYMM' );
    v_last_added_partition := 'M' || TO_CHAR( ADD_MONTHS( SYSDATE, 3 ), 'YYYYMM' );  
    
    IF ( p_reserve_months < c_default_reserve_months ) THEN
      v_reserve_months := c_default_reserve_months;
    ELSE
      v_reserve_months := p_reserve_months;
    END IF;   
    
    IF ( p_prebuild_months < c_default_prebuild_months ) THEN
      v_prebuild_months := c_default_prebuild_months;
    ELSE
      v_prebuild_months := p_prebuild_months;
    END IF;   

  	v_zabbix_partition_pk1 := zabbix_partition_seq.nextval;
  	INSERT INTO zabbix_partition (
       PK1
      ,TABLE_NAME
      ,PARTITION_KEY
      ,RESERVE_MONTHS
      ,PREBUILD_MONTHS
      ,LAST_ADDED_PARTITION
      ,LAST_REMOVED_PARTITION
      ,STATUS
      ,DTCREATED
      ,DTMODIFIED  	
  	)
  	VALUES (
  	   v_zabbix_partition_pk1
  	  ,UPPER(p_table_name)
  	  ,UPPER(p_partition_key)
  	  ,v_reserve_months 
  	  ,v_prebuild_months
  	  ,v_last_added_partition
  	  ,v_last_removed_partition
  	  ,'UC'
  	  ,SYSDATE
  	  ,SYSDATE
  	);
  	COMMIT;
  	
  	write_log( v_zabbix_partition_pk1, 'Regiter new partion table ' || p_table_name || ' to zabbix successfully.' );
  EXCEPTION
    WHEN e_table_not_exist THEN
      DBMS_OUTPUT.PUT_LINE( 'Register Failed: the table( ' || p_table_name || ' ) doesn''t exist.' );
    WHEN e_partition_key_not_exist THEN
      DBMS_OUTPUT.PUT_LINE( 'Register Failed: the partition key( ' || p_partition_key || ' ) doesn''t exist.' );
    WHEN e_dup_register THEN
      DBMS_OUTPUT.PUT_LINE( 'Register Failed: the table( ' || p_table_name || ' ) has been registered.' );
    WHEN e_housekeeper_register THEN
      DBMS_OUTPUT.PUT_LINE( 'Register Failed: the table( ' || p_table_name || ' ) has been registered as housekeeper table.' );
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE( 'Register Failed.' );
      RAISE;
  END register_partition_table;		

  PROCEDURE unregister_housekeeper_table ( p_table_name VARCHAR2 )
  IS
    e_unregister EXCEPTION;  
  BEGIN
    IF ( is_housekeeper_table( p_table_name ) = 'N' ) THEN
      RAISE e_unregister;
    END IF;
    
    DELETE FROM zabbix_housekeeper WHERE table_name = p_table_name;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE( 'Unregister the table ( ' || p_table_name || ' ) Successfully.' );
  EXCEPTION
    WHEN e_unregister THEN
      DBMS_OUTPUT.PUT_LINE( 'Unregister Failed: the table ( ' || p_table_name || ' ) doesn''t exist.' );
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE( 'Unregister Failed.' );
      RAISE;    
  END unregister_housekeeper_table;
  
  PROCEDURE register_housekeeper_table (
    p_table_name VARCHAR2,
    p_del_cond_col_name VARCHAR2,
    p_reserve_days INTEGER := 365 )
  IS
    e_table_not_exist EXCEPTION;
    e_dup_register EXCEPTION;
    e_partition_register EXCEPTION;
    e_partition_key_not_exist EXCEPTION;
  BEGIN
  	IF ( is_housekeeper_table( p_table_name ) = 'Y' ) THEN
  	  RAISE e_dup_register;
    END IF;

  	IF ( is_partition_table( p_table_name ) = 'Y' ) THEN
  	  RAISE e_partition_register;
    END IF;

  	IF ( has_table( p_table_name ) = 'N' ) THEN
  	  RAISE e_table_not_exist;
    END IF;
    
  	IF ( has_column( p_table_name, p_del_cond_col_name ) = 'N' ) THEN
  	  RAISE e_partition_key_not_exist;
    END IF;
    
    IF ( p_reserve_days <= 5 ) THEN
      RAISE INVALID_NUMBER;
    END IF;
     
    INSERT INTO zabbix_housekeeper (
       pk1
      ,table_name
      ,del_cond_col_name
      ,reserve_days
      ,status
      ,dtcreated
      ,dtmodified
    )
    VALUES (
       zabbix_housekeeper_seq.nextval
      ,UPPER( p_table_name )
      ,UPPER( p_del_cond_col_name )
      ,p_reserve_days
      ,'U'
      ,SYSDATE
      ,SYSDATE
    );  
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE( 'Regiter new hosekeeper table ' || p_table_name || ' to zabbix successfully.' );
  EXCEPTION
    WHEN e_table_not_exist THEN
      DBMS_OUTPUT.PUT_LINE( 'Register Failed: the table( ' || p_table_name || ' ) doesn''t exist.' );
    WHEN e_dup_register THEN
      DBMS_OUTPUT.PUT_LINE( 'Register Failed: the table( ' || p_table_name || ' ) has been registered.' );
    WHEN e_partition_register THEN
      DBMS_OUTPUT.PUT_LINE( 'Register Failed: the table( ' || p_table_name || ' ) has been registered as partition table.' );
    WHEN e_partition_key_not_exist THEN
      DBMS_OUTPUT.PUT_LINE( 'Register Failed: the delete condition column name ( ' || p_del_cond_col_name || ' ) doesn''t exist.' );
    WHEN INVALID_NUMBER THEN
      DBMS_OUTPUT.PUT_LINE( 'Register Failed: the parameter ( p_reserve_days ) should be > 5.' );    
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE( 'Register Failed.' );
      RAISE;
  END register_housekeeper_table;  

  PROCEDURE housekeeper_cleanup ( p_table_name VARCHAR2 := NULL )
  IS
    e_table_not_exist EXCEPTION;
    v_sql VARCHAR2(200);
    v_del_cond_col_name VARCHAR2(30);
    v_reserve_days NUMBER;
  BEGIN
    IF ( p_table_name IS NOT NULL ) THEN
      IF ( is_housekeeper_table( p_table_name ) = 'N' OR has_table( p_table_name ) = 'N' ) THEN
        RAISE e_table_not_exist;
      END IF;
      
      SELECT del_cond_col_name, reserve_days 
        INTO v_del_cond_col_name, v_reserve_days 
        FROM zabbix_housekeeper 
       WHERE table_name = UPPER( p_table_name );
      
      v_sql := 'DELETE FROM ' || p_table_name || ' WHERE ' || v_del_cond_col_name || ' < ' || oracle_to_unix( trunc(sysdate) - v_reserve_days );
      EXECUTE IMMEDIATE v_sql;
      
      UPDATE zabbix_housekeeper SET status = 'S' WHERE table_name = p_table_name;
      COMMIT;
      
      DBMS_OUTPUT.PUT_LINE( 'Housekeeper cleanup for the table ( ' || p_table_name || ' ) successfully.' ); 
    ELSE
      FOR cs_tablename In ( SELECT table_name FROM zabbix_housekeeper )
      LOOP
        housekeeper_cleanup ( cs_tablename.table_name );
      END LOOP;
    END IF;
  EXCEPTION
    WHEN e_table_not_exist THEN
      DBMS_OUTPUT.PUT_LINE( 'Housekeeper cleanup Failed: the table( ' || p_table_name || ' ) doesn''t exist.' );
    WHEN OTHERS THEN
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE( 'Housekeeper cleanup Failed.' );
      RAISE;
  END housekeeper_cleanup;
  
  PROCEDURE add_partitions ( p_table_name VARCHAR2 := NULL )
  IS
    v_zabbix_partition_pk1 NUMBER;
    v_prebuild_months INTEGER;
    v_last_added_partition VARCHAR2(30);
    v_target_partition VARCHAR2(30); 
    v_next_partition VARCHAR2(30); 
    v_unix_time INTEGER;
    v_sql VARCHAR2(1000);
  BEGIN
    IF ( p_table_name IS NOT NULL ) THEN
      UPDATE zabbix_partition
         SET status = 'F'
       WHERE table_name = p_table_name;
      COMMIT;
      
      SELECT pk1, prebuild_months, last_added_partition
        INTO v_zabbix_partition_pk1, v_prebuild_months, v_last_added_partition
        FROM zabbix_partition
       WHERE table_name = p_table_name;
      
      v_target_partition := 'M' || TO_CHAR( ADD_MONTHS( SYSDATE, v_prebuild_months ), 'YYYYMM' );
      v_next_partition := 'M' || TO_CHAR( ADD_MONTHS( TO_DATE( SUBSTR( v_last_added_partition, 2 ) || '01', 'YYYYMMDD' ), 1 ), 'YYYYMM' );
      v_unix_time := oracle_to_unix( ADD_MONTHS( TO_DATE( SUBSTR( v_next_partition, 2 ) || '01', 'YYYYMMDD' ), 1 ) );
      
      WHILE ( v_next_partition <= v_target_partition ) LOOP
        v_sql := 'ALTER TABLE ' || p_table_name || ' ADD PARTITION ' || v_next_partition || ' VALUES LESS THAN ( ' || v_unix_time || ' )';
        EXECUTE IMMEDIATE v_sql;
        
        UPDATE zabbix_partition 
           SET last_added_partition = v_next_partition
         WHERE table_name = p_table_name;
         
        INSERT INTO zabbix_partition_log ( 
          pk1, 
          zabbix_partition_pk1, 
          dtcreated, 
          message 
        )
        VALUES (
          zabbix_partition_log_seq.nextval,
          v_zabbix_partition_pk1,
          SYSDATE,
          'Add new partion ' || v_next_partition || ' to ' || p_table_name
        );  
        COMMIT;
        
        v_next_partition := 'M' || TO_CHAR( ADD_MONTHS( TO_DATE( SUBSTR( v_next_partition, 2 ) || '01', 'YYYYMMDD' ), 1 ), 'YYYYMM' );
        v_unix_time := oracle_to_unix( ADD_MONTHS( TO_DATE( SUBSTR( v_next_partition, 2 ) || '01', 'YYYYMMDD' ), 1 ) );        
      END LOOP; 
      
      UPDATE zabbix_partition
         SET status = 'S'
       WHERE table_name = p_table_name;
      COMMIT;
    ELSE
      FOR cs_partition_table IN ( SELECT table_name FROM zabbix_partition ) LOOP
        add_partitions ( cs_partition_table.table_name );
      END LOOP;  
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;      
  END add_partitions;
  
  PROCEDURE remove_partitions ( p_table_name VARCHAR2 := NULL )
  IS
    v_zabbix_partition_pk1 NUMBER;
    v_reserve_months INTEGER;
    v_last_removed_partition VARCHAR2(30);
    v_target_partition VARCHAR2(30); 
    v_next_partition VARCHAR2(30); 
    v_sql VARCHAR2(1000);
  BEGIN
    IF ( p_table_name IS NOT NULL ) THEN
      UPDATE zabbix_partition
         SET status = 'F'
       WHERE table_name = p_table_name;
      COMMIT;

      SELECT pk1, reserve_months, last_removed_partition
        INTO v_zabbix_partition_pk1, v_reserve_months, v_last_removed_partition
        FROM zabbix_partition
       WHERE table_name = p_table_name;
      
      v_target_partition := 'M' || TO_CHAR( ADD_MONTHS( SYSDATE, -v_reserve_months ), 'YYYYMM' );
      v_next_partition := 'M' || TO_CHAR( ADD_MONTHS( TO_DATE( SUBSTR( v_last_removed_partition, 2 ) || '01', 'YYYYMMDD' ), 1 ), 'YYYYMM' );
      
      WHILE ( v_next_partition < v_target_partition ) LOOP
        V_SQL := 'CREATE TABLE ' || p_table_name || '_' || v_next_partition || ' AS SELECT * FROM ' || p_table_name || ' WHERE 1 = 2';
        EXECUTE IMMEDIATE v_sql;        
         
        v_sql := 'ALTER TABLE ' || p_table_name || ' EXCHANGE PARTITION ' || v_next_partition || ' WITH TABLE ' || p_table_name || '_' || v_next_partition || ' WITH VALIDATION';
        EXECUTE IMMEDIATE v_sql;        
        
        v_sql := 'ALTER TABLE ' || p_table_name || ' DROP PARTITION ' || v_next_partition ;
        EXECUTE IMMEDIATE v_sql;        

        UPDATE zabbix_partition 
           SET last_removed_partition = v_next_partition,
               dtmodified = SYSDATE
         WHERE table_name = p_table_name;
         
        INSERT INTO zabbix_partition_log ( 
          pk1, 
          zabbix_partition_pk1, 
          dtcreated, 
          message 
        )
        VALUES (
          zabbix_partition_log_seq.nextval,
          v_zabbix_partition_pk1,
          SYSDATE,
          'Removed old partion ' || v_next_partition || ' from ' || p_table_name
        );  

        INSERT INTO zabbix_partition_arch ( 
          pk1, 
          zabbix_partition_pk1,
          table_name,
          partition_name,
          archive_table_name,
          archive_ind, 
          dtcreated,
          dtmodified 
        )
        VALUES (
          zabbix_partition_arch_seq.nextval,
          v_zabbix_partition_pk1,
          p_table_name,
          v_next_partition,
          p_table_name || '_' || v_next_partition,
          'N',
          SYSDATE,
          SYSDATE
        );  
        COMMIT;
        
        v_next_partition := 'M' || TO_CHAR( ADD_MONTHS( TO_DATE( SUBSTR( v_next_partition, 2 ) || '01', 'YYYYMMDD' ), 1 ), 'YYYYMM' );
      END LOOP; 

      UPDATE zabbix_partition
         SET status = 'S'
       WHERE table_name = p_table_name;
      COMMIT;
    ELSE
      FOR cs_partition_table IN ( SELECT table_name FROM zabbix_partition ) LOOP
        remove_partitions ( cs_partition_table.table_name );
      END LOOP;  
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
  END remove_partitions;

  PROCEDURE convert_to_partition (
    p_tablename VARCHAR2 := NULL,
    p_forscript CHAR := 'Y' 
  ) 
  IS 
    c_crlf CONSTANT VARCHAR2(20) := CHR(13) || CHR(10);
    c_execute_char CONSTANT VARCHAR2(20) := c_crlf || '/' || c_crlf;

    v_sql VARCHAR2(8000);
    v_old_tablename VARCHAR2(30);
    v_new_tablename VARCHAR2(30);
    v_column_name VARCHAR2(500);
    v_pk1 NUMBER;
    v_status CHAR(2);
    v_partition_key VARCHAR2(30);
    v_last_added_partition VARCHAR2(30);
    v_last_removed_partition VARCHAR2(30);
    v_target_partition VARCHAR2(30); 
    v_next_partition VARCHAR2(30); 
    v_unix_time INTEGER;
    v_script VARCHAR2(8000);
    v_tablespace_name VARCHAR2(30);
    
    CURSOR cs_primary_key ( p_tablename VARCHAR2 ) IS
      SELECT ucc.column_name, uc.index_name
        FROM user_constraints uc
       INNER JOIN user_cons_columns ucc ON uc.table_name = ucc.table_name AND uc.constraint_name = ucc.constraint_name
       WHERE uc.table_name = p_tablename
         AND uc.constraint_type = 'P'
       ORDER BY ucc.column_name;
    CURSOR cs_index ( p_tablename VARCHAR2 ) IS
      SELECT ui.index_name, ui.uniqueness
        FROM user_indexes ui
       WHERE ui.table_name = p_tablename
         AND NOT EXISTS ( SELECT 1 FROM user_constraints uc WHERE uc.table_name = ui.table_name AND uc.index_name = ui.index_name ) 
       ORDER BY ui.index_name;
    CURSOR cs_index_column ( p_tablename VARCHAR2, p_index_name VARCHAR2 ) IS
      SELECT uic.column_name, uic.descend
        FROM user_ind_columns uic
       WHERE uic.table_name = p_tablename
         AND uic.index_name = p_index_name
       ORDER BY uic.column_position;
    CURSOR cs_index_name ( p_tablename VARCHAR2 ) IS
      SELECT ui.index_name
        FROM user_indexes ui
       WHERE ui.table_name = p_tablename
         AND NOT EXISTS ( SELECT 1 FROM user_constraints uc WHERE uc.table_name = ui.table_name AND uc.index_name = ui.index_name ) ;
  BEGIN
    IF ( p_tablename IS NOT NULL ) THEN
      v_old_tablename := UPPER( p_tablename );
      
      -- Create the partition table
      SELECT pk1, partition_key, last_added_partition, last_removed_partition, status
        INTO v_pk1, v_partition_key, v_last_added_partition, v_last_removed_partition, v_status
        FROM zabbix_partition
       WHERE table_name = v_old_tablename;
       
      v_script := ' /*************************************************************** ' || c_crlf
               || '  * ' || c_crlf
               || '  * Convert the regular table to partition table - ' || v_old_tablename || c_crlf
               || '  * ' || c_crlf
               || '  ***************************************************************/' || c_crlf
               || ' -- Create the partition table for ' || p_tablename || c_crlf; 
      v_new_tablename := 'NEW_' || v_old_tablename;
      
      v_sql := ' CREATE TABLE ' || v_new_tablename || c_crlf
            || ' PARTITION BY RANGE(' || v_partition_key || ') ' || c_crlf
            || ' ( ' || c_crlf;
      
      v_target_partition := v_last_added_partition;
      v_next_partition := 'M' || TO_CHAR( ADD_MONTHS( TO_DATE( SUBSTR( v_last_removed_partition, 2 ) || '01', 'YYYYMMDD' ), 1 ), 'YYYYMM' );
      v_unix_time := oracle_to_unix( ADD_MONTHS( TO_DATE( SUBSTR( v_next_partition, 2 ) || '01', 'YYYYMMDD' ), 1 ) );
      
      WHILE ( v_next_partition <= v_target_partition ) 
      LOOP
        v_sql := v_sql || ' PARTITION ' || v_next_partition || ' VALUES LESS THAN ( ' || v_unix_time || ' ), ' || c_crlf;
        
        v_next_partition := 'M' || TO_CHAR( ADD_MONTHS( TO_DATE( SUBSTR( v_next_partition, 2 ) || '01', 'YYYYMMDD' ), 1 ), 'YYYYMM' );
        v_unix_time := oracle_to_unix( ADD_MONTHS( TO_DATE( SUBSTR( v_next_partition, 2 ) || '01', 'YYYYMMDD' ), 1 ) );                  
      END LOOP;
      
      v_tablespace_name := get_tablespace_name ( v_old_tablename, 'TABLE' );
      v_sql := SUBSTR( v_sql, 1, LENGTH( v_sql ) - 4 ) || ' ) ' || c_crlf
            || ' TABLESPACE ' || v_tablespace_name || c_crlf
            || ' AS ' || c_crlf
            || ' SELECT * FROM ' || v_old_tablename ||  ' WHERE 1=2 ';
            
      v_script := v_script || v_sql || c_execute_char || c_crlf; 
      execute_sql( v_sql, v_pk1, 'C',  'Create the ' || v_new_tablename || ' partition table successfully.', p_forscript );
      
      -- Fill data from regular table into partition table
      v_sql := ' INSERT INTO ' || v_new_tablename 
            || ' SELECT /*+ APPEND */ * FROM ' || v_old_tablename;
      v_script := v_script || '-- Fill data into the ' || v_new_tablename || c_crlf
               || v_sql || c_execute_char; 
      execute_sql( v_sql, v_pk1, 'F',  'Fill the data into the ' || v_new_tablename || ' partition table successfully.', p_forscript );
     
      
      -- Create the primary key for the partition table
      v_column_name := ' '; 
      FOR c_primary_key IN cs_primary_key ( v_old_tablename ) LOOP
        v_column_name := v_column_name || c_primary_key.column_name || ', '; 
        v_tablespace_name := get_tablespace_name( c_primary_key.index_name, 'INDEX' );
      END LOOP;
      
      IF ( v_column_name <> ' ' ) THEN
      	IF ( INSTR( v_column_name, v_partition_key ) = 0 ) THEN
          v_column_name := v_partition_key || ', ' || v_column_name;
      	END IF; 
        v_column_name := ' ( ' || SUBSTR( v_column_name, 1, LENGTH( v_column_name ) - 2 ) || ' ) ';
        v_sql := ' ALTER TABLE ' || v_new_tablename || ' ADD PRIMARY KEY ' || c_crlf 
              || v_column_name  || c_crlf
              || ' USING INDEX ' || ' TABLESPACE ' || v_tablespace_name || ' COMPUTE STATISTICS LOCAL '; 
        v_script := v_script || '-- Create the primary key for ' || v_new_tablename || c_crlf
                 || v_sql || c_execute_char; 
        execute_sql( v_sql, v_pk1, 'P', 'Create the primary key for ' || v_new_tablename || ' successfully.', p_forscript );
      END IF;
      
      
      -- Create the indexes for partition table
      v_script := v_script || '-- Create the indexes for ' || v_new_tablename || c_crlf;
      FOR c_index IN cs_index( v_old_tablename ) LOOP
        v_sql := 'CREATE' || CASE WHEN c_index.uniqueness = 'UNIQUE' THEN 'UNIQUE' ELSE ' ' END
              || ' INDEX NEW_' || c_index.index_name || ' ON ' || v_new_tablename || c_crlf;  
              
        v_column_name := ' '; 
        FOR c_index_column IN cs_index_column( v_old_tablename, c_index.index_name ) LOOP
          v_column_name := v_column_name || c_index_column.column_name || ' ' || c_index_column.descend || ', '; 
        END LOOP;
        
        IF ( c_index.uniqueness = 'UNIQUE' AND INSTR( v_column_name, v_partition_key ) = 0 ) THEN
        	v_column_name := v_partition_key || ', ' || v_column_name;
        END IF;
        v_column_name := ' ( ' || SUBSTR( v_column_name, 1, LENGTH( v_column_name ) - 2 ) || ' ) ' || c_crlf;  

        v_tablespace_name := get_tablespace_name( c_index.index_name, 'INDEX' );
        v_sql := v_sql || v_column_name || ' TABLESPACE ' || v_tablespace_name || ' COMPUTE STATISTICS LOCAL ' || c_crlf;  
        v_script := v_script || v_sql || c_execute_char; 
        execute_sql( v_sql, v_pk1, NULL, NULL, p_forscript );
      END LOOP; 
      change_status ( v_pk1, 'I', 'Create the index for ' || v_new_tablename || ' successfully.', p_forscript );  
      
              
      -- Exchange the index name for regular table and partition table
      v_script := v_script || '-- Exchange the index name for regular table and partition table' || c_crlf;
      FOR c_index_name IN cs_index_name( v_old_tablename ) LOOP
        v_sql := 'ALTER INDEX ' || c_index_name.index_name || ' RENAME TO OLD_' || c_index_name.index_name;
        v_script := v_script || v_sql || c_execute_char; 
        execute_sql( v_sql, v_pk1, NULL, NULL, p_forscript );
        v_sql := 'ALTER INDEX NEW_' || c_index_name.index_name || ' RENAME TO ' || c_index_name.index_name;
        v_script := v_script || v_sql || c_execute_char; 
        execute_sql( v_sql, v_pk1, NULL, NULL, p_forscript );
      END LOOP;
      change_status ( v_pk1, 'EI', 'Exchange the table name for regular table and partition table ' || v_new_tablename || ' successfully.', p_forscript );    

      -- Exchange the table name for regular table and partition table
      v_script := v_script || '-- Exchange the table name for regular table and partition table' || c_crlf;
      v_sql := 'ALTER TABLE ' || v_old_tablename || ' RENAME TO OLD_' || v_old_tablename;
      v_script := v_script || v_sql || c_execute_char; 
      execute_sql( v_sql, v_pk1, NULL, NULL, p_forscript );
      v_sql := 'ALTER TABLE ' || v_new_tablename || ' RENAME TO ' || v_old_tablename;
      v_script := v_script || v_sql || c_execute_char;
      execute_sql( v_sql, v_pk1, 'ET', 'Exchange the table name for regular table and partition table ' || v_new_tablename || ' successfully.', p_forscript );
      
      -- Generate the convertation script
      IF ( p_forscript = 'Y' ) THEN
        output_script( v_script );
      END IF;
    ELSE
      FOR cs_tablename IN (
        SELECT table_name, status
          FROM zabbix_partition
      )
      LOOP
        IF ( p_forscript = 'Y' OR ( cs_tablename.status = 'UC' AND p_forscript = 'N' ) ) THEN
          convert_to_partition ( cs_tablename.table_name, p_forscript );
        END IF;  
      END LOOP;       
    END IF;
  END convert_to_partition;
END zabbix_maintaince;
/
EXIT;

