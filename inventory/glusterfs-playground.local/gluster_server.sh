#!/bin/bash

# gluster_server.sh
#
# Script to deploy GlusterFS server on rfi CentOS7
#
# The script is not idempotent!
#
# MAINTAINERS:
# Vitaliy Dmitriev

set -e

########
# vars #
########
SVC_TO_DISABLE="clientdata dnscache dns-monitor graphite-proxy logstash-shipper puppet4"
BRICK1_PATH="/bricks/brick1"
BRICK_DEVICE="/dev/md2"

################
# prepare host #
################
yum -y install bash-completion

for svc in $SVC_TO_DISABLE
do
  svc -d /service/$svc
  touch /service/$svc/down
  svstat /service/$svc
done
echo "[INFO] wait for all the services to stop"
sleep 20

mkdir -p $BRICK1_PATH

umount /srv/data/disk1
sed -i 's/.*\/srv\/data\/disk1.*//' /etc/fstab
echo "[INFO] fstab after cleanup:"
cat /etc/fstab
mkfs.xfs -f -i size=512 $BRICK_DEVICE
# export device UUID as $UUID env var
eval `blkid -o export $BRICK_DEVICE`
echo "UUID=$UUID $BRICK1_PATH          xfs     defaults        1 2" >> /etc/fstab
echo "[INFO] fstab after \"$BRICK1_PATH\" has been added:"
cat /etc/fstab
mount -a
echo "[INFO] \"$BRICK1_PATH\" mount info:"
findmnt $BRICK1_PATH

############################
# Install GlusterFS server #
############################
yum -y install centos-release-gluster
yum -y install glusterfs-server
systemctl enable glusterd
systemctl start glusterd
echo "[INFO] glusterd service status:"
systemctl status glusterd
