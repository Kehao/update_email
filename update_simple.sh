#!/bin/bash
MYSQL=`which mysql`
DIR=`dirname $0`
CALLER=`basename $0`
USER=root
PASSWD=
HOST=127.0.0.1
PIDFILE=$DIR/update.pid
OUTFILE=$DIR/update.log


usage()
{
 echo "   USAGE: $CALLER [-h 127.0.0.1] [-u root] [-p password] -d database [-D]"
 echo "         -h mysql host,default value:127.0.0.1"
 echo "         -u mysql user,default value:root"
 echo "         -p mysql password,default value:null"
 echo "         -d mysql database"
 echo "         -D self-daemonizing "
 echo "                             "
 echo "   $CALLER  clean: rm $OUTFILE and $PIDFILE"
 echo "   $CALLER  help: show this usage"
 exit 1
}
clean()
{
  if [ -f "$OUTFILE" ]; then
    rm "$OUTFILE"
  fi
  if [ -f "$PIDFILE" ]; then
    rm "$PIDFILE"
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

$ENCRYPT_COMMAND << EOF
UPDATE users SET mail = CONCAT('ps-',uid,'@',RTRIM(SUBSTRING_INDEX(mail, '@', -1)));
UPDATE email_subscriptions SET email = CONCAT('ps-',id,'@',RTRIM(SUBSTRING_INDEX(email, '@', -1)));
UPDATE email_subscriptions_global SET email = CONCAT('ps-',id,'@',RTRIM(SUBSTRING_INDEX(email, '@', -1)));
EOF

exit 0
