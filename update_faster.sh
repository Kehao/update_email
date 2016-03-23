#!/bin/bash
MYSQL=`which mysql`
DIR=`dirname $0`
CALLER=`basename $0`
USER=root
PASSWD=
HOST=127.0.0.1
PIDFILE=$DIR/update.pid
OUTFILE=$DIR/update.log
LOCALFILE=$DIR/update.local


usage()
{
 echo "   USAGE: $CALLER [-h 127.0.0.1] [-u root] [-p password] -d database [-D]"
 echo "         -h mysql host,default value:127.0.0.1"
 echo "         -u mysql user,default value:root"
 echo "         -p mysql password,default value:null"
 echo "         -d mysql database"
 echo "         -D self-daemonizing "
 echo "                             "
 echo "   $CALLER  clean: rm $OUTFILE,$LOCALFILE,$PIDFILE and drop procedures"
 echo "   $CALLER  status: show status table"
 echo "   $CALLER  help: show this usage"
 exit 1
}
clean()
{
  ENCRYPT_COMMAND=`echo $(head -1 $LOCALFILE)`
$ENCRYPT_COMMAND << EOF
DROP PROCEDURE IF EXISTS pager;
DROP PROCEDURE IF EXISTS update_dev_email;
DROP PROCEDURE IF EXISTS update_email;

DROP TABLE IF EXISTS updated_users;
DROP TABLE IF EXISTS updated_email_subscriptions;
DROP TABLE IF EXISTS updated_email_subscriptions_global;
DROP TABLE IF EXISTS db_pager_status;
EOF

  if [ -f "$OUTFILE" ]; then
    rm "$OUTFILE"
  fi
  if [ -f "$PIDFILE" ]; then
    rm "$PIDFILE"
  fi
  if [ -f "$LOCALFILE" ]; then
    rm "$LOCALFILE"
  fi
  exit 0
}
status()
{
 if [ -f "$LOCALFILE" ]; then
  ENCRYPT_COMMAND=`echo $(head -1 $LOCALFILE)`

$ENCRYPT_COMMAND << EOF
SELECT * FROM db_pager_status;
EOF
 else
  echo "$CALLER is not running!"
 fi
 exit 0
}

if [[ $# -lt 1 ]];then
  usage
fi
if [[ $1 = 'help' ]];then
  usage
fi
if [[ $1 = 'clean' ]];then
  clean
fi
if [[ $1 = 'status' ]];then
  status
fi
while getopts ":h:u:p:d:D" OPTION
do
    case $OPTION in
    h)
    HOST=$OPTARG
    ;;
    u)
    USER=$OPTARG
    ;;
    p)
    PASSWD=$OPTARG
    ;;
    d)
    DATABASE=$OPTARG
    ;;
    D)
    Daemon=true
    ;;
    ?)
    usage
    ;;
    esac
done

if [ ! -n "$DATABASE" ]; then
  echo "DATABASE must be specified!,$CALLER -h for help!"
  exit 1
fi

OPTIONS="-h$HOST -u$USER -p$PASSWD -D$DATABASE"

PASSWD_LEN=${#PASSWD}
if [[ ${PASSWD_LEN} -eq 0 ]];then
  OPTIONS="-h$HOST -u$USER -D$DATABASE"
fi

if [ -n "$Daemon" ];then
  array=($*)
  cmd="./$CALLER ${array[@] //'-D'/}"
  nohup $cmd>>$OUTFILE 2>&1 & echo $!>$PIDFILE
  exit 0
fi

ENCRYPT_COMMAND="$MYSQL $OPTIONS"

if [ -f "$LOCALFILE" ]; then
  rm "$LOCALFILE"
fi
touch "$LOCALFILE"
echo $ENCRYPT_COMMAND > $LOCALFILE

$ENCRYPT_COMMAND < update_dev_email.sql
$ENCRYPT_COMMAND < pager.sql
$ENCRYPT_COMMAND < update.sql

$ENCRYPT_COMMAND << EOF
CALL update_email();
EOF

exit 0;
