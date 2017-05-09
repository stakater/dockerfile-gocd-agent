FROM stakater/base-alpine:3.5
LABEL authors="Hazim <hazim_malik@hotmail.com>"

ARG GOCD_VERSION="17.4.0"
ARG GID=1001
ARG UID=1001
ARG DOWNLOAD_URL="https://download.gocd.io/binaries/17.4.0-4892/generic/go-agent-17.4.0-4892.zip"
LABEL gocd.version="${GOCD_VERSION}" \
  description="GoCD agent based on alpine version 3.5" \
  gocd.full.version="17.4.0-4892" \
  gocd.git.sha="ab17b819e73477a47401744fa64f64fda55c26e8"

ADD ${DOWNLOAD_URL} /tmp/go-agent.zip
ADD https://github.com/krallin/tini/releases/download/v0.14.0/tini-static-amd64 /usr/local/sbin/tini
ADD https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64 /usr/local/sbin/gosu

# allow mounting ssh keys, dotfiles, and the go server config and data
VOLUME /godata

RUN \
# add mode and permissions for files we added above
  chmod 0755 /usr/local/sbin/tini && \
  chown root:root /usr/local/sbin/tini && \
  chmod 0755 /usr/local/sbin/gosu && \
  chown root:root /usr/local/sbin/gosu && \
# add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
  addgroup -g ${GID} go && \
  adduser -D -u ${UID} -G go go && \
  apk --update-cache upgrade && \
  apk add --update-cache openjdk8-jre-base git mercurial subversion openssh-client jq libuuid wget py-pip python3 && \
  pip install --upgrade pip && \
  pip install --upgrade awscli && \
  pip3 install ruamel.yaml && \
# unzip the zip file into /go-agent, after stripping the first path prefix
  unzip /tmp/go-agent.zip -d / && \
  mv go-agent-${GOCD_VERSION} /go-agent && \
  rm /tmp/go-agent.zip

# Add go user to list of sudoers
ADD sudoers/go /etc/sudoers.d/
RUN chmod 755 /etc/sudoers.d/go

# Install terraform
ARG TERRAFORM_VERSION="0.7.13"
RUN mkdir -p /opt/terraform && \
    wget -nc -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -P /opt/terraform && \
    unzip -q /opt/terraform/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /opt/terraform && \
    rm -rf /opt/terraform/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

ENV PATH /opt/terraform:$PATH

# Install glibc to be able to use mapped docker and docker-compose
# inside the container
RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.25-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    wget \
        "https://raw.githubusercontent.com/andyshinn/alpine-pkg-glibc/master/sgerrand.rsa.pub" \
        -O "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

ENV LANG=C.UTF-8

# Simulate cmd behavior via environment variable``
# So that users are able to provice command line arguments to gocd-server
ENV 	COMMAND ""

# Make daemon service dir for gocd-server and place file
# It will be started and maintained by the base image
RUN 	mkdir -p /etc/service/gocd-agent
ADD 	start.sh /etc/service/gocd-agent/run