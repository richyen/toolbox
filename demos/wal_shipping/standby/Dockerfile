FROM postgres:18

RUN apt-get update && apt-get install -y rsync && rm -rf /var/lib/apt/lists/*

# Local WAL cache — restore_command reads from here first.
RUN mkdir -p /archive && chown postgres:postgres /archive

COPY restore_wal.sh   /usr/local/bin/restore_wal.sh
COPY entrypoint.sh    /entrypoint.sh

RUN chmod +x /usr/local/bin/restore_wal.sh /entrypoint.sh

EXPOSE 5432

ENTRYPOINT ["/entrypoint.sh"]
