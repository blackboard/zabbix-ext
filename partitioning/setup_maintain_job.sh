#!/bin/sh

BASE_DIR=$(dirname $0)
if [ $BASE_DIR = '.' ] 
then
  BASE_DIR=$PWD
fi
tmp=${TMPDIR:-/tmp}/xyz.$$
maintain_job=${BASE_DIR}/maintain.sh
trap "rm -f $tmp; exit 1" 0 1 2 3 13 15
crontab -l | sed '%${maintain_job}%d' > $tmp  # Capture crontab; delete old entry
echo "0 1 * * sun ${maintain_job}" >> $tmp
crontab < $tmp
rm -f $tmp
trap 0