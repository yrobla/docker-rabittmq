#
# RabbitMQ Dockerfile
#
# https://github.com/dockerfile/rabbitmq
#

# Pull base image.
FROM ubuntu:trusty
RUN apt-get update
RUN DEBCONF_FRONTEND="noninteractive" apt-get -y --force-yes -o DPkg::Options::="--force-overwrite" -o DPkg::Options::="--force-confdef" install wget pwgen

# Install RabbitMQ.
RUN \
  wget -qO - https://www.rabbitmq.com/rabbitmq-signing-key-public.asc | apt-key add - && \
  echo "deb http://www.rabbitmq.com/debian/ testing main" > /etc/apt/sources.list.d/rabbitmq.list && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y rabbitmq-server && \
  rm -rf /var/lib/apt/lists/* && \
  rabbitmq-plugins enable rabbitmq_management && \
  echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config

# Define environment variables.
ENV RABBITMQ_LOG_BASE /data/log
ENV RABBITMQ_MNESIA_BASE /data/mnesia
ENV RABBITMQ_NODE_PORT 31672
ENV RABBITMQ_DIST_PORT 31673

# Define mount points.
VOLUME ["/data/log", "/data/mnesia"]

# Define working directory.
WORKDIR /data

# install a script to setup the cluster based on DNS
ADD ./rabbitmq-cluster /usr/sbin/rabbitmq-cluster

# set password
ADD ./set_rabbitmq_password.sh /home/set_rabbitmq_password.sh

EXPOSE 31672
EXPOSE 31673
# create a shell so we can configure clustering and stuff
CMD /home/set_rabbitmq_password.sh && /usr/sbin/rabbitmq-cluster
