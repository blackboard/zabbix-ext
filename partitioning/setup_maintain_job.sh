#!/bin/sh

BASE_DIR=$PWD
tmp=${TMPDIR:-/tmp}/xyz.$$
maintain_job=${BASE_DIR}/maintain.sh
trap "rm -f $tmp; exit 1" 0 1 2 3 13 15
echo "0 1 * * sun ${maintain_job}" >> $tmp
crontab < $tmp
rm -f $tmp
trap 0
