#!/bin/sh

BASE_DIR=$(dirname $0)
if [ $BASE_DIR = '.' ] 
then
  BASE_DIR=$PWD
fi

. $BASE_DIR/env.sh

execute_sql_query $SCRIPT_REGISTER_DEFAULT_HOUSEKEEPER_TABLE
execute_sql_query $SCRIPT_REGISTER_DEFAULT_PARTITION_TABLE

