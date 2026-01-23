FROM maven:3.8.6-openjdk-8-slim AS build

WORKDIR /app

COPY . .

RUN mvn -B -V clean package -DskipTests -Dmaven.javadoc.skip=true

FROM tomcat:9-jdk8

ENV DATA_DIR=/catalogue-data
ENV JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom -Djava.awt.headless=true \
        -Xms512M -Xss512M -Xmx2G -XX:+UseConcMarkSweepGC \
        -Dgeonetwork.resources.dir=${DATA_DIR}/resources \
        -Dgeonetwork.data.dir=${DATA_DIR} \
        -Dgeonetwork.codeList.dir=/usr/local/tomcat/webapps/geonetwork/WEB-INF/data/config/codelist \
        -Dgeonetwork.schema.dir=/usr/local/tomcat/webapps/geonetwork/WEB-INF/data/config/schema_plugins"

USER root
RUN apt-get -y update && \
    apt-get -y install --no-install-recommends \
        curl \
        unzip \
	postgresql-client && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p ${DATA_DIR} && \
    mkdir -p /usr/local/tomcat/webapps/geonetwork

COPY --from=build /app/web/target/geonetwork.war /usr/local/tomcat/webapps/geonetwork/geonetwork.war
    
RUN cd /usr/local/tomcat/webapps/geonetwork/ && unzip geonetwork.war && rm geonetwork.war

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/local/tomcat/bin/catalina.sh", "run"]

VOLUME [ "${DATA_DIR}" ]
