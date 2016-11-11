#!/bin/bash
set -e

CONFIG_FILE=/etc/virtuoso/virtuoso.ini

if [ $VIRTUOSO_DBA_PWD != "dba" ] && [ ! -f $PWD/.dba_pwd_changed ]; then
  virtuoso-t -f -c "$CONFIG_FILE" +pwdold dba +pwddba $VIRTUOSO_DBA_PWD
  touch $PWD/.dba_pwd_changed
  echo "DBA default password changed"
fi

virtuoso-t -f -c "$CONFIG_FILE"
