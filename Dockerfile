FROM debian:latest

RUN apt-get update && apt-get install -y gnupg curl wget
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN apt-get update && apt-get install -y software-properties-common postgresql-11 postgresql-client-11 postgresql-contrib-11

USER postgres

RUN    /etc/init.d/postgresql start && \
    psql --command "CREATE USER bosca WITH LOGIN SUPERUSER PASSWORD 'bosca';" && \
    createdb -O bosca bosca

RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/11/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/11/main/postgresql.conf

VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

USER root

COPY start-postgres.sh /
RUN chmod ugo+x /start-postgres.sh

ARG deb=java-11-amazon-corretto-jdk_11.0.3.7-1_amd64.deb
ARG path=https://d3pxv6yz143wms.cloudfront.net/11.0.3.7.1
ARG checksum=3cd63c9f1669e16e513755356ac0cf91

RUN apt-get update && apt-get install -y java-common

RUN curl -sSL -o $deb -O $path/$deb
RUN echo "$checksum $deb" | md5sum -c -
RUN dpkg --install $deb
RUN rm $deb

ENV JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto

RUN java -version

COPY project /project
RUN chmod ugo+x /project/gradlew
RUN cd /project && ./gradlew assemble

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -yq nodejs build-essential



