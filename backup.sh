#!/bin/bash

set -e
export PATH=$PATH:usr/local/bin/influx
export S3_BUCKET=${S3_BUCKET}
: ${S3_BUCKET:?"S3_BUCKET env variable is required"}
: ${AWS_SECRET_ACCESS_KEY:?"AWS_SECRET_ACCESS_KEY env variable is required"}
: ${AWS_ACCESS_KEY_ID:?"AWS_ACCESS_KEY_ID env variable is required"}
: ${INFLUXDB_HOST:?"INFLUXDB_HOST env variable is required"}
: ${INFLUXDB_ORG:?"INFLUXDB_ORG env variable is required"}
: ${INFLUXDB_TOKEN:?"INFLUXDB_TOKEN env variable is required"}
if [[ -z ${S3_PREFIX} ]]; then
  export S3_PREFIX=""
else
  if [ "${S3_PREFIX: -1}" != "/" ]; then
    export S3_PREFIX="${S3_PREFIX}/"
  fi
fi
export BACKUP_PATH=${BACKUP_PATH:-/data/influxdb/backup}
export BACKUP_ARCHIVE_PATH=${BACKUP_ARCHIVE_PATH:-${BACKUP_PATH}.tgz}
export INFLUXDB_HOST=${INFLUXDB_HOST:-influxdb}
export INFLUXDB_ORG=${INFLUXDB_ORG:-influx}
export INFLUXDB_BACKUP_PORT=${INFLUXDB_BACKUP_PORT:-8086}
export CRON=${CRON:-"* * 0 0 *"}
export DATETIME=$(date "+%Y%m%d%H%M%S")

startcron() {
  echo "export PATH=$PATH:user/local/bin/influx" >> $HOME/.profile
  echo "export S3_BUCKET=$S3_BUCKET" >> $HOME/.profile
  echo "export S3_PREFIX=$S3_PREFIX" >> $HOME/.profile
  echo "export INFLUXDB_HOST=$INFLUXDB_HOST" >> $HOME/.profile
  echo "export INFLUXDB_TOKEN=$INFLUXDB_TOKEN" >> $HOME/.profile
  echo "export INFLUXDB_ORG=$INFLUXDB_ORG" >> $HOME/.profile
  echo "export INFLUXDB_BACKUP_PORT=$INFLUXDB_BACKUP_PORT" >> $HOME/.profile
  echo "export BACKUP_PATH=$BACKUP_PATH" >> $HOME/.profile
  echo "export BACKUP_ARCHIVE_PATH=$BACKUP_ARCHIVE_PATH" >> $HOME/.profile
  echo "export DATETIME=$DATETIME" >> $HOME/.profile
  echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> $HOME/.profile
  echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> $HOME/.profile
  echo "Starting backup cron job with frequency '$1'"

  echo "$1 . $HOME/.profile; $0 backup >> /var/log/cron.log 2>&1" > /etc/cron.d/influxdbbackup

  cat /etc/cron.d/influxdbbackup
  crontab /etc/cron.d/influxdbbackup
  touch /var/log/cron.log
  cron && tail -f /var/log/cron.log
}

backup() {
  echo "Backing up to $BACKUP_PATH"
  if [ -d $BACKUP_PATH ]; then
    rm -rf $BACKUP_PATH
  fi
  mkdir -p $BACKUP_PATH
  influx backup --host http://$INFLUXDB_HOST:$INFLUXDB_BACKUP_PORT --org $INFLUXDB_ORG --token $INFLUXDB_TOKEN $BACKUP_PATH/
  if [ $? -ne 0 ]; then
    echo "Failed to backup to $BACKUP_PATH"
    exit 1
  fi

  if [ -e $BACKUP_ARCHIVE_PATH ]; then
    rm -rf $BACKUP_ARCHIVE_PATH
  fi
  tar -cvzf $BACKUP_ARCHIVE_PATH $BACKUP_PATH

  echo "Sending file to S3"
  if aws s3 rm s3://${S3_BUCKET}/${S3_PREFIX}latest.tgz; then
    echo "Removed latest backup from S3"
  else
    echo "No latest backup exists in S3"
  fi
  if aws s3 cp $BACKUP_ARCHIVE_PATH s3://${S3_BUCKET}/${S3_PREFIX}latest.tgz; then
    echo "Backup file copied to s3://${S3_BUCKET}/${S3_PREFIX}latest.tgz"
  else
    echo "Backup file failed to upload"
    exit 1
  fi
  if aws s3api copy-object --copy-source ${S3_BUCKET}/${S3_PREFIX}latest.tgz --key ${S3_PREFIX}${DATETIME}.tgz --bucket $S3_BUCKET; then
    echo "Backup file copied to s3://${S3_BUCKET}/${S3_PREFIX}${DATETIME}.tgz"
  else
    echo "Failed to create timestamped backup"
    exit 1
  fi

  echo "Backup is finished!"
}

restore() {
  if [ -d $BACKUP_PATH ]; then
    echo "Removing out of date backup"
    rm -rf $BACKUP_PATH
  fi
  if [ -e $BACKUP_ARCHIVE_PATH ]; then
    echo "Removing out of date backup"
    rm -rf $BACKUP_ARCHIVE_PATH
  fi
  echo "Downloading latest backup from S3"
  if aws s3 cp s3://${S3_BUCKET}/${S3_PREFIX}latest.tgz $BACKUP_ARCHIVE_PATH; then
    echo "Downloaded"
  elses
    echo "Failed to download latest backup"
    exit 1
  fi
  mkdir -p $BACKUP_PATH
  tar -xvzf $BACKUP_ARCHIVE_PATH -c $BACKUP_PATH

  echo "Running restore"
  if influx restore --host $INFLUXDB_HOST:$INFLUXDB_BACKUP_PORT --org $INFLUXDB_ORG --token $INFLUXDB_TOKEN --full $BACKUP_PATH ; then
    echo "Successfully restored"
  else
    echo "Restore failed"
    exit 1
  fi
  echo "Done"

}

case "$1" in
  "startcron")
    startcron "$CRON"
    ;;
  "backup")
    backup
    ;;
  "restore")
    restore
    ;;
  *)
    echo "Invalid command '$@'"
    echo "Usage: $0 {backup|restore|startcron}"
esac
