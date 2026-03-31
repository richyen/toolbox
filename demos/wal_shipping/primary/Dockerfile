FROM postgres:18

RUN apt-get update && apt-get install -y rsync && rm -rf /var/lib/apt/lists/*

# Archive directory — owned by postgres so archive_command can write here
RUN mkdir -p /archive && chown postgres:postgres /archive

COPY rsyncd.conf      /etc/rsyncd.conf
COPY initdb/          /docker-entrypoint-initdb.d/
COPY entrypoint.sh    /entrypoint.sh

RUN chmod +x /entrypoint.sh \
 && chmod +x /docker-entrypoint-initdb.d/*.sh

EXPOSE 5432 873

ENTRYPOINT ["/entrypoint.sh"]
