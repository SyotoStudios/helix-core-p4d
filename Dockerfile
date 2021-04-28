FROM ubuntu:xenial

LABEL vendor="Perforce Software"
LABEL maintainer="Paul Allen (pallen@perforce.com)"

# Update Ubuntu and add Perforce Package Source
RUN \
  apt-get update && \
  apt-get install -y wget unzip vim  && \
  wget -qO - https://package.perforce.com/perforce.pubkey | apt-key add - && \
  echo "deb http://package.perforce.com/apt/ubuntu xenial release" > /etc/apt/sources.list.d/perforce.list && \
  apt-get update

# --------------------------------------------------------------------------------
# Docker ENVIRONMENT
# --------------------------------------------------------------------------------

# Default Environment
ARG P4NAME=master
ARG P4TCP=1666
ARG P4USER=super
ARG P4PASSWD=Passw0rd
ARG P4CASE=-C0
ARG P4CHARSET=utf8

# Dynamic Environment
ENV P4NAME=$P4NAME \
  P4TCP=$P4TCP \
  P4PORT=$P4TCP \
  P4USER=$P4USER \
  P4PASSWD=$P4PASSWD \
  P4CASE=$P4CASE \
  P4CHARSET=$P4CHARSET \
  JNL_PREFIX=$P4NAME

# Base Environment
ENV P4HOME=/p4
ENV P4LOGDIR=$P4HOME/log

# Derived Environment
ENV P4ROOT=$P4HOME/root \
  P4DEPOTS=$P4HOME/depots \
  P4CKP=$P4HOME/checkpoints \
  P4JOURNAL=$P4LOGDIR/journal \
  P4LOG=$P4LOGDIR/p4d.log

# --------------------------------------------------------------------------------
# Docker BUILD
# --------------------------------------------------------------------------------

# Create perforce user and install Perforce Server
RUN \
  apt-get install -y helix-p4d && \
  apt-get install -y helix-swarm-triggers

# Add external files
COPY files/clean.sh /usr/local/bin/clean.sh
COPY files/restore.sh /usr/local/bin/restore.sh
COPY files/empty_setup.sh /usr/local/bin/empty_setup.sh
COPY files/init.sh /usr/local/bin/init.sh
COPY files/latest_checkpoint.sh /usr/local/bin/latest_checkpoint.sh

RUN \
  chmod +x /usr/local/bin/clean.sh && \
  chmod +x /usr/local/bin/restore.sh && \
  chmod +x /usr/local/bin/empty_setup.sh && \
  chmod +x /usr/local/bin/init.sh && \
  chmod +x /usr/local/bin/latest_checkpoint.sh

# Expose Perforce; TCP port and volumes
EXPOSE $P4TCP
VOLUME $P4HOME


# --------------------------------------------------------------------------------
# Docker RUN
# --------------------------------------------------------------------------------

ENTRYPOINT \
  init.sh && \
  sleep infinity

HEALTHCHECK \
  --interval=2m \
  --timeout=10s \
  CMD p4 info -s > /dev/null || exit 1