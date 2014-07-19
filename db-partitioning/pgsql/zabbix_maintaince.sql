CREATE TABLE zabbix_partition_arch (
    pk1 bigint NOT NULL,
    zabbix_partition_pk1 bigint NOT NULL,
    table_name varchar(30) NOT NULL,
    partition_name varchar(30) NOT NULL,
    archive_table_name varchar(30) NOT NULL,
    archive_ind char(1) NOT NULL DEFAULT 'N',
    dtcreated timestamp NOT NULL,
    dtmodified timestamp NOT NULL,
    archive_full_path_name varchar(1000)
);
ALTER TABLE zabbix_partition_arch ADD PRIMARY KEY (pk1);
CREATE INDEX zabbix_partition_arch_ie2 ON zabbix_partition_arch (dtcreated);
CREATE INDEX zabbix_partition_arch_ie1 ON zabbix_partition_arch (zabbix_partition_pk1);
CREATE TABLE zabbix_partition (
    pk1 bigint NOT NULL,
    table_name varchar(30) NOT NULL,
    partition_key varchar(30) NOT NULL,
    reserve_months bigint NOT NULL DEFAULT 12,
    prebuild_months bigint NOT NULL DEFAULT 3,
    last_added_partition varchar(30) NOT NULL,
    last_removed_partition varchar(30) NOT NULL,
    status char(2) NOT NULL DEFAULT 'U',
    dtcreated timestamp NOT NULL,
    dtmodified timestamp NOT NULL
);
ALTER TABLE zabbix_partition ADD PRIMARY KEY (pk1);
CREATE UNIQUE INDEX zabbix_partition_ak1 ON zabbix_partition (table_name);
CREATE TABLE zabbix_partition_log (
    pk1 bigint NOT NULL,
    zabbix_partition_pk1 bigint NOT NULL,
    dtcreated timestamp NOT NULL,
    message varchar(2000)
);
ALTER TABLE zabbix_partition_log ADD PRIMARY KEY (pk1);
CREATE INDEX zabbix_partition_log_ie1 ON zabbix_partition_log (zabbix_partition_pk1);
CREATE INDEX zabbix_partition_log_ie2 ON zabbix_partition_log (dtcreated);
CREATE TABLE zabbix_housekeeper (
    pk1 bigint NOT NULL,
    table_name varchar(30) NOT NULL,
    del_cond_col_name varchar(30) NOT NULL,
    reserve_days bigint NOT NULL DEFAULT 365,
    status char(1) NOT NULL DEFAULT 'U',
    dtcreated timestamp NOT NULL,
    dtmodified timestamp NOT NULL
);
ALTER TABLE zabbix_housekeeper ADD PRIMARY KEY (pk1);

CREATE UNIQUE INDEX zabbix_housekeeper_ak1 ON zabbix_housekeeper (table_name);
CREATE SEQUENCE zabbix_housekeeper_seq INCREMENT 1 MINVALUE 1 NO MAXVALUE START 1 CACHE 20;
CREATE SEQUENCE zabbix_partition_arch_seq INCREMENT 1 MINVALUE 1 NO MAXVALUE START 1 CACHE 20;
CREATE SEQUENCE zabbix_partition_log_seq INCREMENT 1 MINVALUE 1 NO MAXVALUE START 1 CACHE 20;
CREATE SEQUENCE zabbix_partition_seq INCREMENT 1 MINVALUE 1 NO MAXVALUE START 1 CACHE 20;

-- Oracle package 'ZABBIX_MAINTAINCE' declaration, please edit to match PostgreSQL syntax.
-- PostgreSQL does not recognize PACKAGES, using SCHEMA instead.
DROP SCHEMA IF EXISTS zabbix_maintaince CASCADE;
CREATE SCHEMA zabbix_maintaince;

CREATE OR REPLACE FUNCTION zabbix_maintaince.pgsql_to_unix ( p_pgsql_date timestamp )
  RETURNS bigint AS $body$
BEGIN
  RETURN( extract(epoch FROM date_trunc( 'second', p_pgsql_date ) ) );
END;
$body$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION zabbix_maintaince.unix_to_pgsql ( p_unix_time bigint )
  RETURNS timestamp AS $body$
BEGIN
  RETURN(TIMESTAMP WITH TIME ZONE 'epoch' + p_unix_time * INTERVAL '1 second');
 END;
$body$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION zabbix_maintaince.has_table ( p_table_name text )
  RETURNS char AS $body$
DECLARE
 v_count integer;
BEGIN
  -- Check if the table exists
  SELECT COUNT(1) INTO v_count FROM information_schema.tables WHERE table_name = lower( p_table_name );
  IF ( v_count = 0 ) THEN
    RETURN 'N';
  ELSE
    RETURN 'Y';
  END IF;
END;
$body$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION zabbix_maintaince.has_column ( p_table_name text, p_partition_key text )
  RETURNS char AS $body$
DECLARE
  v_count integer;
BEGIN
 	-- Check if the partition key exists
 	SELECT COUNT(1) INTO v_count FROM information_schema.columns WHERE table_name = lower( p_table_name ) AND column_name = lower( p_partition_key );
 	IF ( v_count = 0 ) THEN
 	  RETURN 'N';
 	ELSE
 	  RETURN 'Y';
  END IF;
 END;
$body$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION zabbix_maintaince.is_partition_table ( p_table_name text )
  RETURNS char AS $body$
DECLARE
  v_count integer;
BEGIN
 	-- Check if it is a partition table
 	SELECT COUNT(1) INTO v_count FROM zabbix_partition WHERE table_name = UPPER( p_table_name );
 	IF ( v_count = 0 ) THEN
 	  RETURN 'N';
 	ELSE
 	  RETURN 'Y';
  END IF;
END;
$body$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION zabbix_maintaince.is_housekeeper_table ( p_table_name text )
  RETURNS char AS $body$
DECLARE
  v_count integer;
BEGIN
 	-- Check if it is a housekeeper table
 	SELECT COUNT(1) INTO v_count FROM zabbix_housekeeper WHERE table_name = UPPER( p_table_name );
 	IF ( v_count = 0 ) THEN
 	  RETURN 'N';
 	ELSE
 	  RETURN 'Y';
  END IF;
 END;
$body$
LANGUAGE PLPGSQL;

CREATE FUNCTION zabbix_maintaince.instr(string varchar, string_to_search varchar, beg_index integer)
RETURNS integer AS $$
DECLARE
    pos integer NOT NULL DEFAULT 0;
    temp_str varchar;
    beg integer;
    length integer;
    ss_length integer;
BEGIN
    IF beg_index > 0 THEN
        temp_str := substring(string FROM beg_index);
        pos := position(string_to_search IN temp_str);

        IF pos = 0 THEN
            RETURN 0;
        ELSE
            RETURN pos + beg_index - 1;
        END IF;
    ELSIF beg_index < 0 THEN
        ss_length := char_length(string_to_search);
        length := char_length(string);
        beg := length + beg_index - ss_length + 2;

        WHILE beg > 0 LOOP
            temp_str := substring(string FROM beg FOR ss_length);
            pos := position(string_to_search IN temp_str);

            IF pos > 0 THEN
                RETURN beg;
            END IF;

            beg := beg - 1;
        END LOOP;

        RETURN 0;
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql STRICT IMMUTABLE;

CREATE OR REPLACE FUNCTION zabbix_maintaince.output_script (
  p_script text
)
RETURNS VOID AS $body$
DECLARE
  c_crlf CONSTANT char(2) := CHR(13) || CHR(10);
  c_execute_char CONSTANT char(5) := c_crlf || '/' || c_crlf;
  v_start integer;
  v_end integer;
  v_len integer;
BEGIN
  v_len := length( p_script );
  v_start := 1;
  v_end := zabbix_maintaince.INSTR( p_script, c_crlf, v_start );
  WHILE ( 1 = 1 )
  LOOP
   RAISE NOTICE '%', SUBSTR( p_script, v_start, v_end - v_start ) ;
   v_start := v_end + 2;
   v_end := zabbix_maintaince.INSTR( p_script, c_crlf, v_start );
   IF ( v_end = 0 ) THEN
     v_end := v_len;
   END IF;
   EXIT WHEN v_start > v_len;
  END LOOP;
 END;
$body$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION zabbix_maintaince.execute_sql (
  p_sql text,
  p_pk1 bigint,
  p_status CHAR,
  p_msg text,
  p_forscript CHAR
 )
  RETURNS VOID AS $body$
BEGIN
 	IF ( p_forscript = 'N' ) THEN
 	 EXECUTE zabbix_maintaince.write_log( p_pk1, p_sql );
   EXECUTE p_sql;
   IF ( (p_status IS NOT NULL AND p_status::text <> '') ) THEN
     EXECUTE zabbix_maintaince.change_status ( p_pk1, p_status , p_msg, p_forscript );
   END IF;
  END IF;
 END;
$body$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION zabbix_maintaince.write_log (
  p_pk1 bigint,
  p_msg text
 )
  RETURNS VOID AS $body$
BEGIN
  INSERT INTO zabbix_partition_log (
   pk1,
   zabbix_partition_pk1,
   dtcreated,
   message
  )
  VALUES (
   nextval('zabbix_partition_log_seq'),
   p_pk1,
   LOCALTIMESTAMP,
   p_msg
  );
  RAISE NOTICE '%', p_msg ;
END;
$body$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION zabbix_maintaince.change_status (
  p_pk1 bigint,
  p_status CHAR,
  p_msg text,
  p_forscript CHAR
 )
  RETURNS VOID AS $body$
BEGIN
 	IF ( p_forscript = 'N' ) THEN
    UPDATE zabbix_partition
      SET status = p_status
    WHERE pk1 = p_pk1;
    EXECUTE zabbix_maintaince.write_log( p_pk1, p_msg );
  END IF;
 END;
$body$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION zabbix_maintaince.unregister_partition_table ( p_table_name text )
  RETURNS VOID AS $body$
DECLARE
  v_pk1 bigint;
BEGIN
  IF ( zabbix_maintaince.is_partition_table( p_table_name ) = 'N' ) THEN
   RAISE NOTICE '%', 'Unregister Failed: the table ( ' || p_table_name || ' ) doesn''t exist.' ;
   RETURN;
  END IF;

	SELECT pk1 INTO v_pk1 FROM zabbix_partition WHERE table_name = p_table_name;
 	DELETE FROM zabbix_partition_arch WHERE zabbix_partition_pk1 = v_pk1;
 	DELETE FROM zabbix_partition_log WHERE zabbix_partition_pk1 = v_pk1;
 	DELETE FROM zabbix_partition WHERE pk1 = v_pk1;
  EXECUTE zabbix_maintaince.write_log( v_pk1, 'Unregister the table ( ' ||  p_table_name || ' ) Successfully.' );
END;
$body$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION zabbix_maintaince.register_partition_table (
  p_table_name text,
  p_partition_key text,
  p_reserve_months integer,
  p_prebuild_months integer )
  RETURNS VOID AS $body$
DECLARE
  c_default_reserve_months CONSTANT integer := 3;
  c_default_prebuild_months CONSTANT integer := 3;
  v_zabbix_partition_pk1 bigint;
  v_min_value integer;
  v_max_value integer;
  v_last_removed_partition varchar(30);
  v_last_added_partition varchar(30);
  v_reserve_months integer;
  v_prebuild_months integer;
  v_sql varchar(100);
  v_count integer;
BEGIN
 	IF ( zabbix_maintaince.is_partition_table( p_table_name ) = 'Y' ) THEN
    RAISE NOTICE '%', 'Register Failed: the table( ' || p_table_name || ' ) has been registered.' ;
    RETURN;
  END IF;
 	IF ( zabbix_maintaince.is_housekeeper_table( p_table_name ) = 'Y' ) THEN
    RAISE NOTICE '%', 'Register Failed: the table( ' || p_table_name || ' ) has been registered as housekeeper table.' ;
    RETURN;
  END IF;
 	IF ( zabbix_maintaince.has_table( p_table_name ) = 'N' ) THEN
    RAISE NOTICE '%', 'Register Failed: the table( ' || p_table_name || ' ) doesn''t exist.' ;
    RETURN;
  END IF;
 	IF ( zabbix_maintaince.has_column ( p_table_name, p_partition_key ) = 'N' ) THEN
    RAISE NOTICE '%', 'Register Failed: the partition key( ' || p_partition_key || ' ) doesn''t exist.' ;
    RETURN;
  END IF;
 	v_sql := 'SELECT MIN( ' || p_partition_key || ' ) FROM ' || p_table_name;
  EXECUTE v_sql INTO v_min_value;
  IF ( coalesce(v_min_value::text, '') = '' ) THEN
   v_min_value := zabbix_maintaince.pgsql_to_unix ( LOCALTIMESTAMP );
  END IF;
  v_max_value := zabbix_maintaince.pgsql_to_unix ( LOCALTIMESTAMP );
  v_last_removed_partition := 'M' || TO_CHAR( zabbix_maintaince.unix_to_pgsql( v_min_value ) + '-1 month'::interval, 'YYYYMM' );
  v_last_added_partition := 'M' || TO_CHAR( LOCALTIMESTAMP + '3 month'::interval, 'YYYYMM' );
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
 	v_zabbix_partition_pk1 := nextval('zabbix_partition_seq');
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
 	 ,LOCALTIMESTAMP
 	 ,LOCALTIMESTAMP
 	);
  EXECUTE zabbix_maintaince.write_log( v_zabbix_partition_pk1, 'Regiter new partion table ' || p_table_name || ' to zabbix successfully.' );
END;
$body$
LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION zabbix_maintaince.unregister_housekeeper_table ( p_table_name text )
  RETURNS VOID AS $body$
DECLARE
BEGIN
  IF ( zabbix_maintaince.is_housekeeper_table( p_table_name ) = 'N' ) THEN
   RAISE NOTICE '%', 'Unregister Failed: the table ( ' || p_table_name || ' ) doesn''t exist.' ;
   RETURN;
  END IF;
  
  DELETE FROM zabbix_housekeeper WHERE table_name = p_table_name;
  RAISE NOTICE '%', 'Unregister the table ( ' || p_table_name || ' ) Successfully.' ;
END;
$body$
LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION zabbix_maintaince.register_housekeeper_table (
  p_table_name text,
  p_del_cond_col_name text,
  p_reserve_days integer DEFAULT 365 )
  RETURNS VOID AS $body$
DECLARE
BEGIN
 	IF ( zabbix_maintaince.is_housekeeper_table( p_table_name ) = 'Y' ) THEN
    RAISE NOTICE '%', 'Register Failed: the table( ' || p_table_name || ' ) has been registered.' ;
    RETURN;
  END IF;
 	IF ( zabbix_maintaince.is_partition_table( p_table_name ) = 'Y' ) THEN
    RAISE NOTICE '%', 'Register Failed: the table( ' || p_table_name || ' ) has been registered as partition table.' ;
    RETURN;
  END IF;
 	IF ( zabbix_maintaince.has_table( p_table_name ) = 'N' ) THEN
    RAISE NOTICE '%', 'Register Failed: the table( ' || p_table_name || ' ) doesn''t exist.' ;
    RETURN;
  END IF;
 	IF ( zabbix_maintaince.has_column( p_table_name, p_del_cond_col_name ) = 'N' ) THEN
    RAISE NOTICE '%', 'Register Failed: the delete condition column name ( ' || p_del_cond_col_name || ' ) doesn''t exist.' ;
    RETURN;
  END IF;
  IF ( p_reserve_days <= 5 ) THEN
    RAISE NOTICE '%', 'Register Failed: the parameter ( p_reserve_days ) should be > 5.' ;
    RETURN;
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
    nextval('zabbix_housekeeper_seq')
   ,UPPER( p_table_name )
   ,UPPER( p_del_cond_col_name )
   ,p_reserve_days
   ,'U'
   ,LOCALTIMESTAMP
   ,LOCALTIMESTAMP
  );
  RAISE NOTICE '%',  'Regiter new hosekeeper table ' || p_table_name || ' to zabbix successfully.';
END;
$body$
LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION zabbix_maintaince.housekeeper_cleanup ( p_table_name text DEFAULT NULL )
  RETURNS VOID AS $body$
DECLARE
  v_sql varchar(200);
  v_del_cond_col_name varchar(30);
  v_reserve_days bigint;
  r_tablename RECORD;
--  v_timestamp timestamp;
BEGIN
  IF ( (p_table_name IS NOT NULL AND p_table_name::text <> '') ) THEN
    IF ( zabbix_maintaince.is_housekeeper_table( p_table_name ) = 'N' OR zabbix_maintaince.has_table( p_table_name ) = 'N' ) THEN
      RAISE NOTICE '%', 'Housekeeper cleanup Failed: the table( ' || p_table_name || ' ) doesn''t exist.' ;
      RETURN;
    END IF;
    UPDATE zabbix_housekeeper SET status = 'F' WHERE table_name = p_table_name;
    SELECT del_cond_col_name, reserve_days
      INTO v_del_cond_col_name, v_reserve_days
      FROM zabbix_housekeeper
     WHERE table_name = UPPER( p_table_name );
--    v_timestamp := date_trunc( 'day', LOCALTIMESTAMP) - cast( v_reserve_days || ' days' as interval );
    v_sql := 'DELETE FROM ' || p_table_name || ' WHERE ' || v_del_cond_col_name || ' < ' || zabbix_maintaince.pgsql_to_unix( date_trunc( 'day', LOCALTIMESTAMP) - cast( v_reserve_days || ' days' as interval ) );
    EXECUTE v_sql;
    UPDATE zabbix_housekeeper SET status = 'S' WHERE table_name = p_table_name;
    RAISE NOTICE '%', 'Housekeeper cleanup for the table ( ' || p_table_name || ' ) successfully.' ;
  ELSE
    FOR r_tablename In ( SELECT table_name FROM zabbix_housekeeper )
    LOOP
      EXECUTE zabbix_maintaince.housekeeper_cleanup ( r_tablename.table_name );
    END LOOP;
  END IF;
END;
$body$
LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION zabbix_maintaince.add_partitions ( 
  p_table_name text DEFAULT NULL,
  p_filldata char DEFAULT 'N',
  p_forscript CHAR DEFAULT 'Y')
  RETURNS VOID AS $body$
DECLARE
  c_crlf CONSTANT VARCHAR(20) := CHR(13) || CHR(10);
  c_execute_char CONSTANT VARCHAR(20) := c_crlf || ';' || c_crlf;
  v_script text;
  v_zabbix_partition_pk1 bigint;
  v_table_name varchar(30);
  v_partition_key varchar(30);
  v_prebuild_months integer;
  v_last_added_partition varchar(30);
  v_last_removed_partition varchar(30);
  v_target_partition varchar(30);
  v_next_partition varchar(30);
  v_current_check integer;
  v_next_check integer;
  v_sql varchar(8000);
  v_column_name varchar(1000);
  v_new_column_name varchar(1000);
  v_partition_table varchar(30);
  r_partition_table RECORD;
  r_index RECORD;
  r_column RECORD;
  r_fk RECORD;
BEGIN
  IF ( (p_table_name IS NOT NULL AND p_table_name::text <> '') ) THEN
    v_table_name := lower( p_table_name );
    UPDATE zabbix_partition
      SET status = 'F'
     WHERE table_name = p_table_name;
    SELECT pk1, partition_key, prebuild_months, last_added_partition, last_removed_partition
      INTO v_zabbix_partition_pk1, v_partition_key, v_prebuild_months, v_last_added_partition, v_last_removed_partition
      FROM zabbix_partition
     WHERE table_name = p_table_name;

    v_script := ' /*************************************************************** ' || c_crlf
             || '  * ' || c_crlf
             || '  * Convert the regular table to partition table - ' || p_table_name || c_crlf
             || '  * ' || c_crlf
             || '  ***************************************************************/' || c_crlf
             || ' -- Create the partition table for ' || p_table_name || c_crlf; 

    IF ( p_filldata = 'Y' ) THEN
      v_target_partition = v_last_added_partition;
      v_next_partition := 'M' || TO_CHAR( TO_DATE( substring( v_last_removed_partition, 2 ), 'YYYYMM' ) + '1 month'::interval, 'YYYYMM' );
    ELSE  
      v_target_partition := 'M' || TO_CHAR( date_trunc( 'day', LOCALTIMESTAMP ) + cast( v_prebuild_months || ' months' as interval ), 'YYYYMM' );
      v_next_partition := 'M' || TO_CHAR( TO_DATE( substring( v_last_added_partition, 2 ), 'YYYYMM' ) + '1 month'::interval, 'YYYYMM' );
    END IF;
    v_current_check := zabbix_maintaince.pgsql_to_unix( TO_DATE( substring( v_next_partition, 2 ), 'YYYYMM' ) );
    v_next_check := zabbix_maintaince.pgsql_to_unix( TO_DATE( substring( v_next_partition, 2 ), 'YYYYMM') + '1 month'::interval );
    WHILE ( v_next_partition <= v_target_partition ) LOOP
      v_partition_table := p_table_name || '_'|| v_next_partition;
      v_sql := 'create table ' || v_partition_table || '(check ( ' || v_partition_key || ' >= ' || v_current_check || ' and ' || v_partition_key || ' < ' || v_next_check || '),like ' || p_table_name || ' including defaults including storage) with oids';
      v_script := v_script || v_sql || c_execute_char || c_crlf; 
      EXECUTE zabbix_maintaince.execute_sql( v_sql, v_zabbix_partition_pk1, 'CP',  'Create the ' || v_partition_table || ' partition table successfully.', p_forscript );
      
      v_sql := 'alter table ' || v_partition_table || ' inherit ' || p_table_name;
      v_script := v_script || v_sql || c_execute_char || c_crlf; 
      EXECUTE zabbix_maintaince.execute_sql( v_sql, v_zabbix_partition_pk1, 'SI',  'Set the ' || v_partition_table || ' partition  to inherit ' ||  p_table_name || ' table successfully.', p_forscript );
      
      IF ( p_filldata = 'Y' AND zabbix_maintaince.pgsql_to_unix(localtimestamp) > v_current_check ) THEN
        v_sql := 'insert into ' || v_partition_table || ' select * from only ' || p_table_name || ' where ' || v_partition_key || ' >= ' || v_current_check || ' and ' || v_partition_key || ' < ' || v_next_check;
        v_script := v_script || '-- Fill data into the ' || v_partition_table || c_crlf
                 || v_sql || c_execute_char || c_crlf; 
        EXECUTE zabbix_maintaince.execute_sql( v_sql, v_zabbix_partition_pk1, 'FD',  'Fill the data into the ' || v_partition_table || ' partition table successfully.', p_forscript );
      END IF;
      
      v_script := v_script || '-- Create the indexes for ' || v_partition_table || c_crlf;
      FOR r_index IN ( SELECT indexdef FROM pg_catalog.pg_indexes WHERE tablename = v_table_name ) 
      LOOP 
        v_sql := replace( r_index.indexdef, v_table_name, lower( v_partition_table ) );
        v_script := v_script || v_sql || c_execute_char; 
        EXECUTE zabbix_maintaince.execute_sql( v_sql, v_zabbix_partition_pk1, NULL, NULL, p_forscript );
      END LOOP;
      EXECUTE zabbix_maintaince.change_status ( v_zabbix_partition_pk1, 'CI', 'Create the indexes for ' || v_partition_table || ' successfully.', p_forscript );  
      
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
         nextval('zabbix_partition_log_seq'),
         v_zabbix_partition_pk1,
         LOCALTIMESTAMP,
         'Add new partion ' || v_next_partition || ' to ' || p_table_name
      );
      v_next_partition :=  'M' || TO_CHAR( TO_DATE( substring( v_next_partition, 2 ), 'YYYYMM' ) + '1 month'::interval, 'YYYYMM' );
      v_current_check := zabbix_maintaince.pgsql_to_unix( TO_DATE( substring( v_next_partition, 2 ), 'YYYYMM' ) );
      v_next_check := zabbix_maintaince.pgsql_to_unix( TO_DATE( substring( v_next_partition, 2 ), 'YYYYMM') + '1 month'::interval );
    END LOOP;
    IF ( p_filldata = 'Y' ) THEN
      FOR r_fk IN ( SELECT tc.constraint_name, tc.table_name 
                      FROM information_schema.table_constraints AS tc 
                      JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name
                     WHERE constraint_type = 'FOREIGN KEY' 
                       AND ccu.table_name = v_table_name )
      LOOP
        v_sql := 'alter table ' || r_fk.table_name || ' drop constraint ' || r_fk.constraint_name;
        v_script := v_script || '-- Drop the FK constraint ( ' || r_fk.constraint_name || ' )  from the ' || r_fk.table_name || c_crlf
                 || v_sql || c_execute_char || c_crlf; 
        EXECUTE zabbix_maintaince.execute_sql( v_sql, v_zabbix_partition_pk1, 'DF', 'Drop the FK constraint ( ' || r_fk.constraint_name || ' )  from the ' || r_fk.table_name || ' table successfully.', p_forscript );
      END LOOP;
      v_sql := 'truncate table only ' || p_table_name;
      v_script := v_script || '-- Truncate the parent table ( ' || p_table_name || ' )' || c_crlf
               || v_sql || c_execute_char || c_crlf; 
      EXECUTE zabbix_maintaince.execute_sql( v_sql, v_zabbix_partition_pk1, 'TT', 'Truncate the parent table ( ' || p_table_name || ' ) successfully.', p_forscript );
      
      v_column_name := ' ';
      v_new_column_name := ' ';
      
      FOR r_column IN ( SELECT column_name FROM information_schema.columns WHERE table_name = v_table_name )
      LOOP
        v_column_name := ', ' || r_column.column_name || v_column_name;
        v_new_column_name := '|| '','' ||  NEW.' || r_column.column_name || v_new_column_name;
      END LOOP;
       
      v_sql := ' CREATE OR REPLACE FUNCTION ' || p_table_name || '_insert_trigger() '|| c_crlf
            || ' RETURNS TRIGGER AS $$ ' || c_crlf
            || ' DECLARE ' || c_crlf
            || '   insert_sql TEXT; ' || c_crlf
            || ' BEGIN ' || c_crlf
	    || '   insert_sql:= ''INSERT INTO ' || p_table_name || '_m''' || ' || to_char(to_timestamp(NEW.' || v_partition_key || '),''yyyymm'') || ''' || c_crlf
	    || '               (' || substr( v_column_name, 2 ) || ') VALUES ' || c_crlf
	    || '               ('' || ' || substr( v_new_column_name, 11 ) || ' || '')''; ' || c_crlf
            || ' 	 EXECUTE insert_sql; ' || c_crlf
            || ' 	 RETURN NULL; ' || c_crlf
            || ' END ' || c_crlf
            || ' $$ LANGUAGE plpgsql ';
      v_script := v_script || '-- Create the trigger function for table ( ' || p_table_name || ' )' || c_crlf
               || v_sql || c_execute_char || c_crlf; 
      EXECUTE zabbix_maintaince.execute_sql( v_sql, v_zabbix_partition_pk1, 'CF', 'Create the trigger function for table ( ' || p_table_name || ' ) successfully.', p_forscript );
      
      v_sql := ' CREATE TRIGGER insert_' || p_table_name || '_trigger' || c_crlf
            || ' BEFORE INSERT ON ' || p_table_name || c_crlf
            || ' FOR EACH ROW EXECUTE PROCEDURE ' || p_table_name || '_insert_trigger()';
      v_script := v_script || '-- Create the trigger for table ( ' || p_table_name || ' )' || c_crlf
               || v_sql || c_execute_char || c_crlf; 
      EXECUTE zabbix_maintaince.execute_sql( v_sql, v_zabbix_partition_pk1, 'CT', 'Create the trigger  for table ( ' || p_table_name || ' ) successfully.', p_forscript );
    END IF;
    
    UPDATE zabbix_partition
       SET status = 'S'
     WHERE table_name = p_table_name;

    -- Generate the convertation script
    IF ( p_forscript = 'Y' ) THEN
      EXECUTE zabbix_maintaince.output_script( v_script );
    END IF;    
  ELSE
   FOR r_partition_table IN ( SELECT table_name FROM zabbix_partition ) LOOP
     PERFORM zabbix_maintaince.add_partitions ( r_partition_table.table_name, p_filldata, p_forscript );
   END LOOP;
  END IF;
END;
$body$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION zabbix_maintaince.remove_partitions ( p_table_name text DEFAULT NULL )
  RETURNS VOID AS $body$
DECLARE
  v_zabbix_partition_pk1 bigint;
  v_reserve_months integer;
  v_last_removed_partition varchar(30);
  v_target_partition varchar(30);
  v_next_partition varchar(30);
  v_sql varchar(1000);
  r_partition_table RECORD;
BEGIN
  IF ( (p_table_name IS NOT NULL AND p_table_name::text <> '') ) THEN
    UPDATE zabbix_partition
       SET status = 'F'
     WHERE table_name = p_table_name;
   SELECT pk1, reserve_months, last_removed_partition
     INTO v_zabbix_partition_pk1, v_reserve_months, v_last_removed_partition
     FROM zabbix_partition
    WHERE table_name = p_table_name;
   v_target_partition := 'M' || TO_CHAR( date_trunc( 'day', LOCALTIMESTAMP ) - cast( v_reserve_months || ' months' as interval ), 'YYYYMM' );
   v_next_partition := 'M' || TO_CHAR( TO_DATE( substring( v_last_removed_partition, 2 ), 'YYYYMM' ) + '1 month'::interval, 'YYYYMM' ); 
   WHILE ( v_next_partition < v_target_partition ) LOOP
     v_sql :='alter table ' || p_table_name || '_' || v_next_partition || ' no inherit ' || p_table_name;
     EXECUTE v_sql;
     UPDATE zabbix_partition
        SET last_removed_partition = v_next_partition,
            dtmodified = LOCALTIMESTAMP
      WHERE table_name = p_table_name;
     INSERT INTO zabbix_partition_log (
       pk1,
       zabbix_partition_pk1,
       dtcreated,
       message
     )
     VALUES (
       nextval('zabbix_partition_log_seq'),
       v_zabbix_partition_pk1,
       LOCALTIMESTAMP,
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
       nextval('zabbix_partition_arch_seq'),
       v_zabbix_partition_pk1,
       p_table_name,
       v_next_partition,
       p_table_name || '_' || v_next_partition,
       'N',
       LOCALTIMESTAMP,
       LOCALTIMESTAMP
     );
     v_next_partition := 'M' || TO_CHAR( TO_DATE( substring( v_next_partition, 2 ), 'YYYYMM' ) + '1 month'::interval, 'YYYYMM' ); 
   END LOOP;
   UPDATE zabbix_partition
      SET status = 'S'
    WHERE table_name = p_table_name;
  ELSE
    FOR r_partition_table IN ( SELECT table_name FROM zabbix_partition ) LOOP
      PERFORM zabbix_maintaince.remove_partitions ( r_partition_table.table_name );
    END LOOP;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
   RAISE;
END;
$body$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION zabbix_maintaince.convert_to_partition (
  p_tablename text DEFAULT NULL,
  p_forscript CHAR DEFAULT 'Y'
 )
  RETURNS VOID AS $body$
DECLARE
BEGIN
  IF ( (p_tablename IS NOT NULL AND p_tablename::text <> '') ) THEN
    execute zabbix_maintaince.add_partitions( p_tablename, 'Y', p_forscript );
  ELSE
    execute zabbix_maintaince.add_partitions( p_tablename, 'Y', p_forscript );    
  END IF;
END;
$body$
LANGUAGE PLPGSQL;
