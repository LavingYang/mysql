#!/bin/sh
MYSQL_USER="root"
MYSQL_PASSWORD="in"
MYSQL=$(which mysql)

function get_mysql_status() {
  VAR=$($MYSQL -u$MYSQL_USER -p$MYSQL_PASSWORD -sNe "SHOW GLOBAL STATUS LIKE '$1'" 2> /dev/null | awk '{ print $2 }')
  echo "$VAR"
}

V1=$(get_mysql_status "Innodb_os_log_written")
echo "$V1"

sleep 60s

V2=$(get_mysql_status "Innodb_os_log_written")
echo "$V2"

echo $((($V2-$V1)*60/1024/1024)) "MB"