FROM ubuntu:18.04 as BUILD
RUN apt-get update && apt-get upgrade && apt-get install -y squid
WORKDIR /etc/squid/ 
RUN head -n 12 /etc/ssl/openssl.cnf > /etc/ssl/_openssl.cnf && tail -n +14 /etc/ssl/openssl.cnf >> /etc/ssl/_openssl.cnf && mv /etc/ssl/_openssl.cnf /etc/ssl/openssl.cnf
RUN head -n 59 /etc/ssl/openssl.cnf > /etc/ssl/_openssl.cnf && tail -n +61 /etc/ssl/openssl.cnf >> /etc/ssl/_openssl.cnf && mv /etc/ssl/_openssl.cnf /etc/ssl/openssl.cnf
COPY . .
RUN sh ./generate_cert_docker.sh
RUN touch blacklist && touch whitelist && cp whitelist whitelist_ssl && cp blacklist blacklist_ssl
RUN /etc/init.d/squid stop
ENTRYPOINT ["entrypoint.sh"]
