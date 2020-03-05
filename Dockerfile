FROM ubuntu:18.04 as BUILD
LABEL maintainer="hedgehogues@bk.ru"

ENV SQUID_VERSION=3.5.27 \
    SQUID_CACHE_DIR=/var/spool/squid \
    SQUID_LOG_DIR=/var/log/squid \
    SQUID_USER=proxy

RUN apt-get update && apt-get upgrade && apt-get install -y squid=${SQUID_VERSION}*
WORKDIR /etc/squid/ 
RUN head -n 12 /etc/ssl/openssl.cnf > /etc/ssl/_openssl.cnf && tail -n +14 /etc/ssl/openssl.cnf >> /etc/ssl/_openssl.cnf && mv /etc/ssl/_openssl.cnf /etc/ssl/openssl.cnf
RUN head -n 59 /etc/ssl/openssl.cnf > /etc/ssl/_openssl.cnf && tail -n +61 /etc/ssl/openssl.cnf >> /etc/ssl/_openssl.cnf && mv /etc/ssl/_openssl.cnf /etc/ssl/openssl.cnf
COPY . .
RUN sh ./generate_cert_docker.sh
RUN touch blacklist && touch whitelist && cp whitelist whitelist_ssl && cp blacklist blacklist_ssl
RUN /etc/init.d/squid stop
RUN chmod 755 entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]
