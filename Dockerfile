#
# RabbitMQ Dockerfile
#
# https://github.com/dockerfile/rabbitmq
#

# Pull base image.
FROM dockerfile/ubuntu

# Install RabbitMQ.
RUN \
  wget -qO - https://www.rabbitmq.com/rabbitmq-signing-key-public.asc | apt-key add - && \
  echo "deb http://www.rabbitmq.com/debian/ testing main" > /etc/apt/sources.list.d/rabbitmq.list && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y rabbitmq-server && \
  rm -rf /var/lib/apt/lists/* && \
  rabbitmq-plugins enable rabbitmq_management && \
  echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config

# Update rabbitmqctl
ADD ./rabbitmqctl /usr/lib/rabbitmq/bin/rabbitmqctl
RUN chmod 755 /usr/lib/rabbitmq/bin/rabbitmqctl

# Define environment variables.
ENV RABBITMQ_LOG_BASE /data/log
ENV RABBITMQ_MNESIA_BASE /data/mnesia

# Define mount points.
VOLUME ["/data/log", "/data/mnesia"]

# Define working directory.
WORKDIR /data

# install a script to setup the cluster based on DNS
ADD ./rabbitmq-cluster /usr/sbin/rabbitmq-cluster
# expose AMQP port and Management interface and the epmd port, and the inet_dist_listen_min through inet_dist_listen_max ranges
EXPOSE 5672
EXPOSE 15672
EXPOSE 4369
EXPOSE 9100
EXPOSE 9101
EXPOSE 9102
EXPOSE 9103
EXPOSE 9104
EXPOSE 9105
# create a shell so we can configure clustering and stuff
CMD /usr/sbin/rabbitmq-cluster
