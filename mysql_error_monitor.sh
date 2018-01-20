#!/bin/bash

TMP_LOG="/tmp/${0##*/}.log"
Q_LOG=/tmp/lastest.log

VSTART=$(date -d "10 min ago" +"%s")
#start_show=$(date -d @"${VSTART}"  +"%Y/%m/%d %H:%M:%S")

D1MY_CNF=/etc/my.cnf
D2MY_CNF="/etc/mysql/my.cnf"
DF_ERR="$HOSTNAME".err
MYSQL=$(which mysql)
ERR_STRING="ERROR|fail|crash|repair|started"

function get_path () {
  VPATH=$(ps aux | grep mysqld | grep -v mysqld_safe | grep -E "$1" | grep -Po "$1=[A-Za-z0-9\/\.\-\_]*" | awk -F "=" '{print $2}')
  echo "$VPATH"
}

function get_err_from_cnf () {
  ERROR_PATH=$(grep -E 'log_error|log-error' "$1" | awk -F "=" '{print $2}')
  echo "$ERROR_PATH"
}

function get_df_mycnf_errpath () {
  
  local ERR_PATH
  if [ -e "$D1MY_CNF" ]; then
    ERR_PATH=$(get_err_from_cnf "$D1MY_CNF")
  elif [ -e "$D2MY_CNF" ]; then
    ERR_PATH=$(get_err_from_cnf "$D2MY_CNF")
  fi
  
  echo "$ERR_PATH"
}


# Main
MYSQLV=$($MYSQL -V | awk '{ print $5}' | cut -c 1-3)
echo "$MYSQLV"

# Get error path from process parameter
ERROR_PATH=$(get_path "error")
if [[ "$ERROR_PATH" = "" ]]; then
  # Get custom my.cnf path from process parameter
  MYCNF_PATH=$(get_path "file")
  if [[ "$MYCNF_PATH" = "" ]]; then
    # Get errorlog path from default my.cnf path
    ERROR_PATH=$(get_df_mycnf_errpath)
  else
    # Get errorlog path from custom my.cnf path
    ERROR_PATH=$(get_err_from_cnf "$MYCNF_PATH")
  fi
fi

# if you can not find any error path from ps,cnf, ...
# use default error path
if [[ "$ERROR_PATH" = "" ]]; then
  ERROR_PATH=$(find / -type f -name "${DF_ERR}")
fi

cat /dev/null > "$TMP_LOG"

echo "$ERROR_PATH"
tail -n 100 "$ERROR_PATH" | egrep "$ERR_STRING" | grep '^[0-9]' > "$Q_LOG"
#echo ${PIPESTATUS[*]}

while read -r Line
        do
        if [ "$(bc <<< "$MYSQLV <= 5.5")" -eq 1 ]; then
          log_date=$(echo "$Line" | awk '{print $1" "$2}')
          log_date="20${log_date}"
        elif [ "$(bc <<< "$MYSQLV < 5.6")" -eq 1 ]; then
          log_date=$(echo "$Line" | awk '{print $1" "$2}')
        else
          log_date_T=$(echo "$Line" | awk '{print $1}' | awk -F "." '{print $1}')
          log_date=${log_date_T//'T'/' '}
        fi

        Line_time=$(date --date="$log_date" +"%s")
        if [[ "$Line_time" -gt "$VSTART" ]] ; then
          echo "$Line" >> "$TMP_LOG"
        fi
done < "$Q_LOG"

if [ "$(wc -l < "$TMP_LOG")" -gt 0 ];
  then
        mail -s "[ERROR][$HOSTNAME] Error Log Monitor" xxx@xxx.xxx <"$TMP_LOG"
fi

