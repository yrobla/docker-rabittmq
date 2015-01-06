#
# RabbitMQ Dockerfile
#
# https://github.com/dockerfile/rabbitmq
#

# Pull base image.
FROM phusion/baseimage
RUN apt-get update

RUN DEBCONF_FRONTEND="noninteractive" apt-get -y --force-yes -o DPkg::Options::="--force-overwrite" -o DPkg::Options::="--force-confdef" install wget pwgen curl

# Install RabbitMQ.
RUN \
  wget -qO - https://www.rabbitmq.com/rabbitmq-signing-key-public.asc | apt-key add - && \
  echo "deb http://www.rabbitmq.com/debian/ testing main" > /etc/apt/sources.list.d/rabbitmq.list && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y rabbitmq-server && \
  rm -rf /var/lib/apt/lists/* && \
  rabbitmq-plugins enable rabbitmq_management && \
  echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config

# install python and clients
RUN apt-get update && apt-get install -y python python-dev python-pip
RUN pip install marathon

RUN sudo service rabbitmq-server stop

# Define environment variables.
ENV RABBITMQ_NODE_PORT 31672
ENV RABBITMQ_DIST_PORT 31673

# Define mount points.
VOLUME ["/var/log/rabbitmq"]

# install a script to setup the cluster based on DNS
ADD ./rabbitmq-cluster.py /usr/sbin/rabbitmq-cluster.py

# set password
ADD ./set_rabbitmq_password.sh /home/set_rabbitmq_password.sh

# set cookie
ADD ./cookie  /var/lib/rabbitmq/.erlang.cookie
RUN chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
RUN chmod 600 /var/lib/rabbitmq/.erlang.cookie

EXPOSE 31672
EXPOSE 31673
EXPOSE 4369
EXPOSE 15672

# create a shell so we can configure clustering and stuff
CMD /home/set_rabbitmq_password.sh && /usr/sbin/rabbitmq-cluster.py
