#!/bin/sh

BASE_DIR=$(dirname $0)
if [ $BASE_DIR == '.' ] 
then
  BASE_DIR=$PWD
fi

. env.sh

$SQLPLUS $DB_USER/$DB_PASS @$SCRIPT_CONVERT_TO_PARTITION 

