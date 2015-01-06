#!/usr/bin/env python

from marathon import MarathonClient
import os
import subprocess
import time

APP_ID = 'yroblarabbitmq'

# add extra entry for hosts
host = os.getenv('HOST')
if not host:
    host = '127.0.0.1'

current_host = host.replace('.', '-')
with open('/etc/hosts', 'a') as file:
    file.write('127.0.0.1 %s\n' % os.getenv('HOSTNAME'))
    file.write('127.0.0.1 %s\n' % current_host)
os.putenv('HOSTNAME', current_host)

with open('/etc/rabbitmq/rabbitmq-env.conf', 'a') as file:
    file.write('NODENAME=rabbit@%s\n' % current_host)
    file.write('NODE_PORT=31672\n')
    file.write('DIST_PORT=31673\n')

# start rabbit
print "Starting cluster"
endpoint = os.getenv('MARATHON_ENDPOINT')
peers = []
if endpoint:
    try:
        print 'Discovering configuration from %s' % endpoint
        c = MarathonClient('http://%s' % endpoint)
        tasks = c.list_tasks(APP_ID)
        for task in tasks:
            if task.started_at and task.host != host:
                peers.append(task.host)
    except:
        pass

cluster = None
if len(peers) > 0:
    cluster = peers[0]
    print 'Found cluster %s' % cluster

if not cluster:
    # set ha policy
    subprocess.call(['sudo', '-E', 'service', 'rabbitmq-server', 'start'])
    time.sleep(10)
    subprocess.call(['rabbitmqctl', 'set_policy', 'ha-all', '""', '{"ha-mode":"all","ha-sync-mode":"automatic"}'])
else:
    # set entry in hosts for the cluster
    current_cluster = cluster.replace('.', '-')
    with open('/etc/hosts', 'a') as file:
        file.write('%s %s\n' % (cluster, current_cluster))

    subprocess.call(['sudo', '-E', 'service', 'rabbitmq-server', 'start'])
    time.sleep(10)
    subprocess.call(['sudo', '-E', 'rabbitmqctl', 'stop_app'])
    subprocess.call(['sudo', '-E', 'rabbitmqctl', 'reset'])
    subprocess.call(['sudo', '-E', 'rabbitmqctl', 'join_cluster', '--ram', 'rabbit@%s' % current_cluster])
    subprocess.call(['sudo', '-E', 'rabbitmqctl', 'start_app'])
    time.sleep(10)

# sleep forever
while True:
    time.sleep(1)
