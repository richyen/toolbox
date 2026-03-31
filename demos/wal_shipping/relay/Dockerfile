FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y rsync && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /archive /var/log

COPY rsyncd.conf   /etc/rsyncd.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 873

ENTRYPOINT ["/entrypoint.sh"]
