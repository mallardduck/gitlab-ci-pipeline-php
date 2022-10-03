#!/usr/bin/env bash

set -euo pipefail

############################################################
# Speedup DPKG and don't use cache for packages
############################################################
# Taken from here: https://gist.github.com/kwk/55bb5b6a4b7457bef38d
#
# this forces dpkg not to call sync() after package extraction and speeds up
# install
echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup
# we don't need and apt cache in a container
echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache
echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf
export DEBIAN_FRONTEND=noninteractive

  dpkg-reconfigure -f noninteractive tzdata \
  && apt-get update \
  && apt-get install -yq \
      apt-transport-https \
      apt-utils \
      ca-certificates \
      gnupg2 \
      wget \
  && wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | gpg --dearmor | sudo tee /usr/share/keyrings/mongodb-archive-keyring.gpg | gpg --armor \
  && echo "deb http://repo.mongodb.org/apt/debian bullseye/mongodb-org/5.0 main" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list \
  && apt-get update \
  && apt-get install -yq \
      build-essential \
      curl \
      git \
      jq \
      libc-client-dev \
      mariadb-client \
      mongodb-org-tools \
      mongodb-org-shell \
      openssh-client \
      python \
      python-dev \
      rsync \
      sudo \
      unzip \
      zip \
      zlib1g-dev \
      && rm -rf /var/lib/apt/lists/*
