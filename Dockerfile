FROM alpine:3 AS builder

ENV KAFKA_VERSION 3.1.0
ENV SCALA_VERSION 2.13

RUN apk --no-cache update \
 && apk --no-cache upgrade \
 && apk --no-cache add curl gnupg jq \
 && mkdir -p /opt

WORKDIR /opt

RUN curl -sSLO https://downloads.apache.org/kafka/KEYS \
 && gpg --import KEYS \
 && mirror=$(curl --stderr /dev/null https://www.apache.org/dyn/closer.cgi\?as_json\=1 | jq -r '.preferred') \
 && curl -sSLO "${mirror}kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" \
 && curl -sSLO "${mirror}kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz.asc" \
 && gpg --verify "kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz.asc" "kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"

RUN tar xzvf "kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" \
 && mv "/opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}" kafka


FROM alpine:3

RUN apk --no-cache update \
 && apk --no-cache upgrade \
 && apk --no-cache add bash ca-certificates openjdk8-jre su-exec

COPY --from=builder /opt/kafka /opt/kafka

RUN adduser -D -s /bin/bash -Hh /opt/kafka kafka \
 && chown -R kafka:kafka /opt/kafka

WORKDIR /opt/kafka

ENV PATH /opt/kafka/bin:$PATH

COPY config/server.properties /opt/kafka/config/
COPY config/zookeeper.properties /opt/kafka/config/
COPY entrypoint /entrypoint

ENTRYPOINT ["/entrypoint"]
