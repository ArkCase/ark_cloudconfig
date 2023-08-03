#
# Basic Parameters
#
ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG BASE_REPO="arkcase/base"
ARG BASE_TAG="8.7.0"
ARG ARCH="amd64"
ARG OS="linux"
ARG VER="2021.03.27"
ARG PKG="cloudconfig"
ARG SRC="https://project.armedia.com/nexus/repository/arkcase/com/armedia/acm/config-server/${VER}/config-server-${VER}.jar"
ARG APP_USER="${PKG}"
ARG APP_UID="1997"
ARG APP_GROUP="${APP_USER}"
ARG APP_GID="${APP_UID}"
ARG BASE_DIR="/app"
ARG DATA_DIR="${BASE_DIR}/data"
ARG INIT_DIR="${BASE_DIR}/init"
ARG TEMP_DIR="${BASE_DIR}/tmp"
ARG HOME_DIR="${BASE_DIR}/home"
ARG LB_VER="4.20.0"
ARG LB_SRC="https://github.com/liquibase/liquibase/releases/download/v${LB_VER}/liquibase-${LB_VER}.tar.gz"
ARG MARIADB_DRIVER="3.1.2"
ARG MARIADB_DRIVER_URL="https://repo1.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/${MARIADB_DRIVER}/mariadb-java-client-${MARIADB_DRIVER}.jar"
ARG MSSQL_DRIVER="12.2.0.jre11"
ARG MSSQL_DRIVER_URL="https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/${MSSQL_DRIVER}/mssql-jdbc-${MSSQL_DRIVER}.jar"
ARG MYSQL_DRIVER="8.0.32"
ARG MYSQL_DRIVER_URL="https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/${MYSQL_DRIVER}/mysql-connector-j-${MYSQL_DRIVER}.jar"
ARG ORACLE_DRIVER="21.9.0.0"
ARG ORACLE_DRIVER_URL="https://repo1.maven.org/maven2/com/oracle/database/jdbc/ojdbc11/${ORACLE_DRIVER}/ojdbc11-${ORACLE_DRIVER}.jar"
ARG POSTGRES_DRIVER="42.5.4"
ARG POSTGRES_DRIVER_URL="https://repo1.maven.org/maven2/org/postgresql/postgresql/${POSTGRES_DRIVER}/postgresql-${POSTGRES_DRIVER}.jar"

FROM "${PUBLIC_REGISTRY}/${BASE_REPO}:${BASE_TAG}"

#
# Basic Parameters
#
ARG ARCH
ARG OS
ARG VER
ARG PKG
ARG SRC
ARG CONF_TYPE
ARG CONF_SRC
ARG APP_USER
ARG APP_UID
ARG APP_GROUP
ARG APP_GID
ARG BASE_DIR
ARG DATA_DIR
ARG INIT_DIR
ARG TEMP_DIR
ARG HOME_DIR
ARG LB_VER
ARG LB_SRC
ARG MARIADB_DRIVER
ARG MARIADB_DRIVER_URL
ARG MSSQL_DRIVER
ARG MSSQL_DRIVER_URL
ARG MYSQL_DRIVER
ARG MYSQL_DRIVER_URL
ARG ORACLE_DRIVER
ARG ORACLE_DRIVER_URL
ARG POSTGRES_DRIVER
ARG POSTGRES_DRIVER_URL

LABEL ORG="ArkCase LLC"
LABEL MAINTAINER="Armedia Devops Team <devops@armedia.com>"
LABEL APP="Cloudconfig"
LABEL VERSION="${VER}"

# Environment variables
ENV APP_UID="${APP_UID}"
ENV APP_GID="${APP_GID}"
ENV APP_USER="${APP_USER}"
ENV APP_GROUP="${APP_GROUP}"
ENV JAVA_HOME="/usr/lib/jvm/java"
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"
ENV BASE_DIR="${BASE_DIR}"
ENV DATA_DIR="${DATA_DIR}"
ENV INIT_DIR="${INIT_DIR}"
ENV TEMP_DIR="${TEMP_DIR}"
ENV HOME_DIR="${HOME_DIR}"
ENV EXE_JAR="config-server-${VER}.jar"
ENV HOME="${HOME_DIR}"
ENV LB_DIR="${BASE_DIR}/lb"
ENV LB_TAR="${BASE_DIR}/lb.tar.gz"

WORKDIR "${BASE_DIR}"

##########################
# First, install the JDK #
##########################

RUN yum -y update && \
    yum -y install java-11-openjdk-devel && \
    yum -y clean all

#######################################
# Create the requisite user and group #
#######################################
RUN groupadd --system --gid "${APP_GID}" "${APP_GROUP}"
RUN useradd  --system --uid "${APP_UID}" --gid "${APP_GROUP}" --create-home --home-dir "${HOME_DIR}" "${APP_USER}"

#################################
# COPY the application jar file #
#################################
ADD --chown="${APP_USER}:${APP_GROUP}" "${SRC}" "${BASE_DIR}/${EXE_JAR}"
ADD --chown="${APP_USER}:${APP_GROUP}" "entrypoint" "/entrypoint"

##############################################
# Install Liquibase, and add all the drivers #
##############################################
RUN curl -L -o "${LB_TAR}" "${LB_SRC}" && \
    mkdir -p "${LB_DIR}" && \
    tar -C "${LB_DIR}" -xzvf "${LB_TAR}" && \
    rm -rf "${LB_TAR}" && \
    cd "${LB_DIR}" && \
    rm -fv \
        "internal/lib/mssql-jdbc.jar" \
        "internal/lib/ojdbc8.jar" \
        "internal/lib/mariadb-java-client.jar" \
        "internal/lib/postgresql.jar" \
        && \
    curl -L "${MYSQL_DRIVER_URL}" -o "internal/lib/mysql-connector-j-${MYSQL_DRIVER}.jar" && \
    curl -L "${MARIADB_DRIVER_URL}" -o "internal/lib/lib/mariadb-java-client-${MARIADB_DRIVER}.jar" && \
    curl -L "${MSSQL_DRIVER_URL}" -o "internal/lib/lib/mssql-jdbc-${MSSQL_DRIVER}.jar" && \
    curl -L "${ORACLE_DRIVER_URL}" -o "internal/lib/lib/ojdbc11-${ORACLE_DRIVER}.jar" && \
    curl -L "${POSTGRES_DRIVER_URL}" -o "internal/lib/lib/postgresql-${POSTGRES_DRIVER}.jar"

COPY liquibase.properties "${LB_DIR}/"
COPY "sql" "${LB_DIR}/cloudconfig/"

####################################
# Final preparations for execution #
####################################
RUN rm -rf /tmp/*
RUN mkdir -p "${TEMP_DIR}" "${DATA_DIR}"
RUN chown -R "${APP_USER}:${APP_GROUP}" "${BASE_DIR}"
RUN chmod -R "u=rwX,g=rX,o=" "${BASE_DIR}"

USER "${APP_USER}"
EXPOSE 9999
VOLUME [ "${DATA_DIR}" ]
ENTRYPOINT [ "/entrypoint" ]
