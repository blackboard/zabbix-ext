#!/bin/sh

BASE_DIR=$(dirname $0)
if [ $BASE_DIR == '.' ] 
then
  BASE_DIR=$PWD
fi

. $BASE_DIR/env.sh

log_msg "Starting to partition the database, this may take minutes to hours up to table size to be partitioned"
partition