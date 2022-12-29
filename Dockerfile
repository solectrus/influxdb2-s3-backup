FROM influxdb:2.6-alpine
RUN apk add --no-cache aws-cli

COPY backup.sh /usr/bin/backup.sh
RUN chmod u+x /usr/bin/backup.sh
ENTRYPOINT ["/usr/bin/backup.sh"]
CMD ["startcron"]
