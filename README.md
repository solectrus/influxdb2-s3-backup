# influxdb2-s3-backup

Backing up your InfluxDB to AWS S3.

### Default cron (Weekly (Sunday))

```yaml
version: '3.5'

services:
  influxdb:
    image: influxdb:2.7-alpine
    ports:
      - '8086:8086'
    networks:
      - flux-proxy
    environment:
      DOCKER_INFLUXDB_INIT_MODE: 'setup'
      DOCKER_INFLUXDB_INIT_USERNAME: ${INFLUXDB_USERNAME}
      DOCKER_INFLUXDB_INIT_PASSWORD: ${INFLUXDB_PASSWORD}
      DOCKER_INFLUXDB_INIT_ADMIN_TOKEN: ${INFLUXDB_TOKEN}
      DOCKER_INFLUXDB_INIT_ORG: ${INFLUXDB_ORG}
      DOCKER_INFLUXDB_INIT_BUCKET: ${INFLUXDB_DEFAULT_BUCKET}

  fluxbackup:
    image: ghcr.io/solectrus/influxdb2-s3-backup:latest
    networks:
      - flux-proxy
    environment:
      INFLUXDB_HOST: influxdb
      INFLUXDB_ORG: ${INFLUXDB_ORG}
      INFLUXDB_TOKEN: ${INFLUXDB_TOKEN}
      S3_BUCKET: 'S3_bucket_name'
      S3_PREFIX: 'influxdb_backup'
      AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY}
      AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_KEY}
      CRON: '0 0 * * 0'
```
