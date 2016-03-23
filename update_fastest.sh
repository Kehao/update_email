#!/bin/bash
MYSQL=`which mysql`
DIR=`dirname $0`
CALLER=`basename $0`
USER=root
PASSWD=
HOST=127.0.0.1
PIDFILE=$DIR/update.pid
OUTFILE=$DIR/update.log
DATAFOLDER=$DIR/data
TIMESTAMP=`date +%Y-%m-%d-%H-%M-%S`
UPDATED_USERS=`pwd`/data/update_users_$TIMESTAMP.txt
UPDATED_EMAIL_SUBSCRIPTIONS=`pwd`/data/update_email_subscriptions_$TIMESTAMP.txt
UPDATED_EMAIL_SUBSCRIPTIONS_GLOBAL=`pwd`/data/updated_email_subscriptions_global_$TIMESTAMP.txt
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
 echo "   $CALLER  finish: alter the table names"
 echo "   $CALLER  restore: restore the table names"
 echo "   $CALLER  clean: rm $OUTFILE, $PIDFILE and $DATAFOLDER"

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
  if [ -f "$LOCALFILE" ]; then
    rm "$LOCALFILE"
  fi
  if [ -d "$DATAFOLDER" ]; then
    rm -rf "$DATAFOLDER"
  fi
#  if [ -f "$LOCALFILE" ]; then
#ENCRYPT_COMMAND=`echo $(head -1 $LOCALFILE)`
#$ENCRYPT_COMMAND << EOF
#  DROP TABLE IF EXISTS backup_users;
#  DROP TABLE IF EXISTS backup_email_subscriptions;
#  DROP TABLE IF EXISTS backup_email_subscriptions_global;
#EOF
  exit 0
}

finish()
{
 if [ -f "$LOCALFILE" ]; then
  ENCRYPT_COMMAND=`echo $(head -1 $LOCALFILE)`

$ENCRYPT_COMMAND << EOF
  ALTER TABLE users RENAME backup_users;
  ALTER TABLE updated_users RENAME users;

  ALTER TABLE email_subscriptions RENAME backup_email_subscriptions;
  ALTER TABLE updated_email_subscriptions RENAME email_subscriptions;

  ALTER TABLE email_subscriptions_global RENAME backup_email_subscriptions_global;
  ALTER TABLE updated_email_subscriptions_global RENAME email_subscriptions_global;
EOF
 else
  echo "$CALLER is not running!"
 fi
 exit 0
}
restore()
{
 if [ -f "$LOCALFILE" ]; then
  ENCRYPT_COMMAND=`echo $(head -1 $LOCALFILE)`

$ENCRYPT_COMMAND << EOF
  ALTER TABLE users RENAME updated_users;
  ALTER TABLE backup_users RENAME users;

  ALTER TABLE email_subscriptions RENAME updated_email_subscriptions;
  ALTER TABLE backup_email_subscriptions RENAME email_subscriptions;

  ALTER TABLE email_subscriptions_global RENAME updated_email_subscriptions_global;
  ALTER TABLE backup_email_subscriptions_global RENAME email_subscriptions_global;
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
if [[ $1 = 'finish' ]];then
  finish
fi
if [[ $1 = 'restore' ]];then
  restore
fi
if [[ ! -d "$DATAFOLDER" ]];then
 mkdir "$DATAFOLDER"
 chmod u+xw "$DATAFOLDER"
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

$ENCRYPT_COMMAND << EOF
DROP TABLE IF EXISTS updated_users;
CREATE TABLE IF NOT EXISTS updated_users LIKE users;
SELECT uid, name, pass, salt, hash_version,
       CONCAT('ps-',uid,'@',SUBSTRING_INDEX(mail, '@', -1)) as mail,
       mode, sort, threshold, theme, signature, created, access, login,
       status, timezone, language, locale_name, picture, init, source
       FROM users
       INTO OUTFILE "$UPDATED_USERS" FIELDS TERMINATED BY ',';
LOAD DATA LOCAL INFILE "$UPDATED_USERS" INTO TABLE updated_users FIELDS TERMINATED BY ',';

DROP TABLE IF EXISTS updated_email_subscriptions;
CREATE TABLE IF NOT EXISTS updated_email_subscriptions LIKE email_subscriptions;
SELECT id,
       CONCAT('ps-',id,'@',SUBSTRING_INDEX(email, '@', -1)) as email,
       list_id, mail_type, unsub, sub_date, unsub_date, utm_source, utm_medium, utm_content,
       utm_term, utm_campaign, remote_addr, last_engaged,timestamp
       FROM email_subscriptions
       INTO OUTFILE "$UPDATED_EMAIL_SUBSCRIPTIONS" FIELDS TERMINATED BY ',';
LOAD DATA LOCAL INFILE "$UPDATED_EMAIL_SUBSCRIPTIONS" INTO TABLE updated_email_subscriptions FIELDS TERMINATED BY ',';

DROP TABLE IF EXISTS updated_email_subscriptions_global;
CREATE TABLE IF NOT EXISTS updated_email_subscriptions_global LIKE email_subscriptions_global;
SELECT id,uid,
       CONCAT('ps-',id,'@',SUBSTRING_INDEX(email, '@', -1)) as email,
       verified, optout, mxerror, mxcount, city, state, zipcode, timezone, country, metro_area, timestamp
       FROM email_subscriptions_global
       INTO OUTFILE "$UPDATED_EMAIL_SUBSCRIPTIONS_GLOBAL" FIELDS TERMINATED BY ',';
LOAD DATA LOCAL INFILE "$UPDATED_EMAIL_SUBSCRIPTIONS_GLOBAL" INTO TABLE updated_email_subscriptions_global FIELDS TERMINATED BY ',';

EOF

exit 0
