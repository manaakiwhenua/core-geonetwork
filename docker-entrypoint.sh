#!/bin/bash
set -e

export JAVA_OPTIONS=${JAVA_OPTS}

if ! command -v -- "$1" >/dev/null 2>&1 ; then
	set -- java -jar "$JETTY_HOME/start.jar" "$@"
fi

JETTY_BASE=/usr/local/tomcat # I based on a Jetty image, so quickest adjustment!

echo "$@"

if [[ "$1" = /usr/local/tomcat/bin/catalina.sh ]]; then
    # this is a command to run tomcat
    
    # Sanity check: ES_HOST variable is mandatory
    if [ -z "${ES_HOST}" ]; then
        cat >&2 <<- EOWARN
			********************************************************************
			WARNING: Environment variable ES_HOST is mandatory

			GeoNetwork requires an Elasticsearch instance to store the index.
			Please define the variable ES_HOST with the Elasticsearch 
			host name. For example

			docker run -e ES_HOST=elasticsearch geonetwork:${GN_VERSION}

			********************************************************************
		EOWARN
        exit 2
    fi;

    #Setting port
    db_host="${GEONETWORK_DB_HOST:-postgres}"
    db_port="${GEONETWORK_DB_PORT:-5432}"
    echo "db port: $db_port"

    if [ -z "$GEONETWORK_DB_USERNAME" ] || [ -z "$GEONETWORK_DB_PASSWORD" ]; then
        echo >&2 "you must set POSTGRES_DB_USERNAME and POSTGRES_DB_PASSWORD"
        exit 1
    fi

    db_gn="${GEONETWORK_DB_NAME:-geonetwork}"

    #Create databases, if they do not exist yet (http://stackoverflow.com/a/36591842/433558)
    echo  "$db_host:$db_port:*:$GEONETWORK_DB_USERNAME:$GEONETWORK_DB_PASSWORD" > ~/.pgpass
    cat ~/.pgpass
    chmod 0600 ~/.pgpass
    if psql -h "$db_host" -U "$GEONETWORK_DB_USERNAME" -p "$db_port" -d postgres -tqc "SELECT 1 FROM pg_database WHERE datname = '$db_gn'" | grep -q 1; then
        echo "Database '$db_gn' exists; skipping createdb"
    elif psql -h "$db_host" -U "$GEONETWORK_DB_USERNAME" -p "$db_port" -d "$db_gn" -tqc "SELECT 1 FROM pg_database WHERE datname = '$db_gn'" | grep -q 1;then
        echo "Database '$db_gn' already exist; skipping database creation"
    else
        echo "Database '$db_gn' doesn't exist. Creating it..."
        createdb -h "$db_host" -U "$GEONETWORK_DB_USERNAME" -p "$db_port" -O "$GEONETWORK_DB_USERNAME" "$db_gn"
    fi
    rm ~/.pgpass

    # Set Elasticsearch properties
    if [ "${ES_HOST}" != "localhost" ]; then
        sed -i "s#http://localhost:9200#${ES_PROTOCOL:="http"}://${ES_HOST}:${ES_PORT:="9200"}#g" "${JETTY_BASE}/webapps/geonetwork/WEB-INF/web.xml" ;
        sed -i "s#es.host=localhost#es.host=${ES_HOST}#" "${JETTY_BASE}/webapps/geonetwork/WEB-INF/config.properties" ;
    fi; 

    if [ -n "${ES_PROTOCOL}" ] && [ "${ES_PROTOCOL}" != "http" ] ; then
        sed -i "s#es.protocol=http#es.protocol=${ES_PROTOCOL}#" "${JETTY_BASE}/webapps/geonetwork/WEB-INF/config.properties" ;
    fi

    if [ -n "${ES_PORT}" ] && [ "$ES_PORT" != "9200" ] ; then
        sed -i "s#es.port=9200#es.port=${ES_PORT}#" "${JETTY_BASE}/webapps/geonetwork/WEB-INF/config.properties" ;
    fi

    if [ -n "${ES_INDEX_RECORDS}" ] && [ "$ES_INDEX_RECORDS" != "gn-records" ] ; then
        sed -i "s#es.index.records=gn-records#es.index.records=${ES_INDEX_RECORDS}#" "${JETTY_BASE}/webapps/geonetwork/WEB-INF/config.properties" ;
    fi

    if [ "${ES_USERNAME}" != "" ] ; then
        sed -i "s/es.username=.*/es.username=${ES_USERNAME}/" "${JETTY_BASE}/webapps/geonetwork/WEB-INF/config.properties" ;
    fi

    if [ "${ES_PASSWORD}" != "" ] ; then
        sed -i "s/es.password=.*/es.password=${ES_PASSWORD}/" "${JETTY_BASE}/webapps/geonetwork/WEB-INF/config.properties" ;
    fi

    if [ -n "${KB_URL}" ] && [ "$KB_URL" != "http://localhost:5601" ]; then
        sed -i "s#kb.url=http://localhost:5601#kb.url=${KB_URL}#" "${JETTY_BASE}/webapps/geonetwork/WEB-INF/config.properties" ;
        sed -i "s#http://localhost:5601#${KB_URL}#g" "${JETTY_BASE}/webapps/geonetwork/WEB-INF/web.xml" ;
    fi

    # Delegate on base image entrypoint to start jetty
    exec "$@"
else
    exec "$@"
fi
