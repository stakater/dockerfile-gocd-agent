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

# force encoding
ENV LANG=en_US.utf8

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

# Simulate cmd behavior via environment variable
# So that users are able to provice command line arguments to gocd-server
ENV 	COMMAND ""

# Make daemon service dir for gocd-server and place file
# It will be started and maintained by the base image
RUN 	mkdir -p /etc/service/gocd-agent
ADD 	start.sh /etc/service/gocd-agent/run