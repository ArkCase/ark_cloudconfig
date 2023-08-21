#
# Basic Parameters
#
ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG BASE_REPO="arkcase/base"
ARG BASE_TAG="8.8-01"
ARG ARCH="amd64"
ARG OS="linux"
ARG VER="2023.01.03"
ARG BLD="01"
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

WORKDIR "${BASE_DIR}"

##########################
# First, install the JDK #
##########################

RUN yum -y install \
        java-11-openjdk-devel \
    && \
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
