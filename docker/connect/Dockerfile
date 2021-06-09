FROM debezium/connect:1.4 AS build

LABEL maintainer="rgannu"
ENV CONFLUENT_INFLUXDB_CONNECTOR_VERSION=1.2.1

USER root
RUN yum install -y epel-release \
    && yum install -y python-setuptools \
    && yum install -y supervisor unzip jq \
    && yum clean all

COPY ./confluentinc-kafka-connect-influxdb-${CONFLUENT_INFLUXDB_CONNECTOR_VERSION}.zip /kafka/connect/.

RUN unzip /kafka/connect/confluentinc-kafka-connect-influxdb-${CONFLUENT_INFLUXDB_CONNECTOR_VERSION}.zip -d /kafka/connect

COPY ./log4j.properties /kafka/config/log4j.properties

COPY ./supervisor.sh /supervisor.sh
COPY ./config/supervisor/supervisord.conf /etc/supervisord.conf
COPY ./config/init-env.sh /init-env.sh
RUN chmod 755 /supervisor.sh /init-env.sh

ENTRYPOINT ["/bin/bash", "/supervisor.sh"]
