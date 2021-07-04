# influxdb2-s3-backup

Backing up your InfluxDB to AWS S3.

### Default cron (Weekly (Sunday))

```yaml
version: '3.5'

services:
  influxdb:
    image: influxdb:2.0.7
    ports:
      - "8086:8086"
    environment:
      DOCKER_INFLUXDB_INIT_MODE: "setup"
      DOCKER_INFLUXDB_INIT_USERNAME: ${INFLUXDB_USERNAME}
      DOCKER_INFLUXDB_INIT_PASSWORD: ${INFLUXDB_PASSWORD}
      DOCKER_INFLUXDB_INIT_ADMIN_TOKEN: ${INFLUXDB_TOKEN}
      DOCKER_INFLUXDB_INIT_ORG: ${INFLUXDB_ORG}
      DOCKER_INFLUXDB_INIT_BUCKET: ${INFLUXDB_DEFAULT_BUCKET}
      DOCKER_INFLUXDB_BOLT_PATH: "/var/lib/influxdb2/influxdb.bolt"
      DOCKER_INFLUXDB_ENGINE_PATH: "var/lib/influxdb2/engine"
      INFLUXDB_META_DIR: "var/lib/influxdb2/meta"
      INFLUXDB_REPORTING_DISABLED: "false"
      INFLUXD_LOG_LEVEL: "info"
      INFLUXD_BIND_ADDRESS: ":8086
      
  fluxbackup:
    image: buraketmen/influxdb2-s3-backup:latest
    environment:
      INFLUXDB_HOST: influxdb
      INFLUXDB_ORG: ${INFLUXDB_ORG}
      INFLUXDB_TOKEN: ${INFLUXDB_TOKEN}
      INFLUXDB_BACKUP_PORT: 8086
      BACKUP_PATH: '/data/influxdb/backup'
      S3_BUCKET: 'bucket_name'
      S3_PREFIX: 'influxdb_backup'
      AWS_ACCESS_KEY_ID: access_key
      AWS_SECRET_ACCESS_KEY: secret_key
      CRON: '0 0 * * 0'
```
