#
# Basic Parameters
#
ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG ARCH="amd64"
ARG OS="linux"
ARG VER="2.0.0"
ARG JAVA="11"
ARG PKG="cloudconfig"
ARG SRC="com.armedia.acm:config-server:${VER}:jar"
ARG APP_USER="${PKG}"
ARG APP_UID="1997"
ARG APP_GROUP="${APP_USER}"
ARG APP_GID="${APP_UID}"

ARG BASE_REGISTRY="${PUBLIC_REGISTRY}"
ARG BASE_REPO="arkcase/base-java"
ARG BASE_VER="22.04"
ARG BASE_VER_PFX=""
ARG BASE_IMG="${BASE_REGISTRY}/${BASE_REPO}:${BASE_VER_PFX}${BASE_VER}"

#
# The repo from which to pull everything
#
ARG ARKCASE_MVN_REPO="https://nexus.armedia.com/repository/arkcase/"

FROM "${BASE_IMG}"

#
# Basic Parameters
#
ARG ARCH
ARG OS
ARG VER
ARG JAVA
ARG PKG
ARG SRC
ARG APP_USER
ARG APP_UID
ARG APP_GROUP
ARG APP_GID

ARG ARKCASE_MVN_REPO

LABEL ORG="ArkCase LLC"
LABEL MAINTAINER="Armedia Devops Team <devops@armedia.com>"
LABEL APP="Cloudconfig"
LABEL VERSION="${VER}"

# Environment variables
ENV APP_UID="${APP_UID}"
ENV APP_GID="${APP_GID}"
ENV APP_USER="${APP_USER}"
ENV APP_GROUP="${APP_GROUP}"
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"
ENV HOME_DIR="${BASE_DIR}/${PKG}"
ENV HOME="${HOME_DIR}"

WORKDIR "${BASE_DIR}"

############################
# First, set the right JVM #
############################

RUN set-java "${JAVA}"

#######################################
# Create the requisite user and group #
#######################################
RUN groupadd --system --gid "${APP_GID}" "${APP_GROUP}" && \
    useradd  --system --uid "${APP_UID}" --gid "${APP_GROUP}" --groups "${ACM_GROUP}" --create-home --home-dir "${HOME_DIR}" "${APP_USER}"

#################################
# COPY the application jar file #
#################################
ENV EXE_JAR="${BASE_DIR}/${PKG}-${VER}.jar"
ADD --chown="${APP_USER}:${APP_GROUP}" --chmod=0755 "entrypoint" "/entrypoint"
RUN mvn-get "${SRC}" "${ARKCASE_MVN_REPO}" "${EXE_JAR}" && \
    chmod 0444 "${EXE_JAR}"

COPY --chown=root:root --chmod=0755 scripts/* "/usr/local/bin/"
COPY --chown=root:root --chmod=0444 01-developer-mode /etc/sudoers.d
RUN sed -i -e "s;\${ACM_GROUP};${ACM_GROUP};g" /etc/sudoers.d/01-developer-mode

####################################
# Final preparations for execution #
####################################
RUN rm -rf /tmp/* && \
    mkdir -p "${TEMP_DIR}" "${DATA_DIR}" && \
    chown -R "${APP_USER}:${APP_GROUP}" "${BASE_DIR}" && \
    chmod -R "u=rwX,g=rX,o=" "${BASE_DIR}"

USER "${APP_USER}"
EXPOSE 9999
ENTRYPOINT [ "/entrypoint" ]
