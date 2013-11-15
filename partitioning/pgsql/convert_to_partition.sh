#!/bin/sh

BASE_DIR=$(dirname $0)
if [ $BASE_DIR == '.' ] 
then
  BASE_DIR=$PWD
fi

. $BASE_DIR/env.sh

$DB_QUERY_TOOL -U $DB_USER -w $DB_PASS -f $SCRIPT_CONVERT_TO_PARTITION 
