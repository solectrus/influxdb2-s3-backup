# influxdb2-s3-backup

Backing up your InfluxDB to AWS S3.

### Default cron (Weekly (Sunday))

```yaml
version: '3.5'

services:
  influxdb:
    image: influxdb:2.0.7
    environment:
      INFLUXDB_DB: mydb
      INFLUXDB_BIND_ADDRESS: 0.0.0.0:8088
  fluxbackup:
    image: buraketmen/influxdb2-s3-backup:latest
    environment:
      INFLUXDB_HOST: '127.0.0.1'
      INFLUXDB_ORG: 'org_name'
      INFLUXDB_TOKEN: 'secret_token'
      INFLUXDB_BACKUP_PORT: 8088
      BACKUP_PATH: '/data/influxdb/backup'
      S3_BUCKET: 'bucket_name'
      S3_PREFIX: 'influxdb_backup'
      AWS_ACCESS_KEY_ID=access_key
      AWS_SECRET_ACCESS_KEY=secret_key
      CRON: '0 0 * * 0'
```
