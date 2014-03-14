#!/bin/sh

BASE_DIR=$(dirname $0)
if [ $BASE_DIR = '.' ] 
then
  BASE_DIR=$PWD
fi

. $BASE_DIR/env.sh

setup_register_tables
register_default_values
generate_script

