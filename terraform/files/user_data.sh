#!/bin/bash

# specify params required by Smartling SOA AMI
instance_id=$(curl -q http://169.254.169.254/latest/meta-data/instance-id)
instance_ip=$(curl -q http://169.254.169.254/latest/meta-data/local-ipv4)
instance_hostname_prefix="${ecs_cluster_name}"
instance_hostname="$${instance_hostname_prefix}-$${instance_id}"

export HOSTNAME=$${instance_hostname}

/bin/sed "s/^HOSTNAME=.*/HOSTNAME=$HOSTNAME/g" -i /etc/sysconfig/network
echo -ne "127.0.0.1 localhost localhost.localdomain\n127.0.0.1 $HOSTNAME\n" > /etc/hosts
hostname $HOSTNAME

amazon-linux-extras install epel
yum install -y epel-release
### add pdns repo
cat << FILE > /etc/yum.repos.d/powerdns-rec-42.repo
[powerdns-rec-42]
name=PowerDNS repository for PowerDNS Recursor - version 4.2.X
baseurl=http://repo.powerdns.com/centos/x86_64/7/rec-42
gpgkey=https://repo.powerdns.com/FD380FBB-pub.asc
gpgcheck=1
enabled=1
priority=90
includepkg=pdns*
FILE

yum -y makecache; yum -y install vim git nc wget curl

yum install -y atop
systemctl start atop
systemctl enable atop

amazon-linux-extras disable docker
amazon-linux-extras install -y ecs
cat <<FILE > /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "1g"
  }
}
FILE

echo "vm.max_map_count=262144" >> /etc/sysctl.conf
echo "net.core.wmem_max=2097152" >> /etc/sysctl.conf
echo "net.core.rmem_max=2097152" >> /etc/sysctl.conf
sysctl -p

# install pdns-recursor
# you need that protobuf, because pdns-recursor doesn't work on one provided my AL2
wget http://cbs.centos.org/kojifiles/packages/protobuf/2.5.0/10.el7.centos/x86_64/protobuf-2.5.0-10.el7.centos.x86_64.rpm && yum install -y protobuf-2.5.0-10.el7.centos.x86_64.rpm
yum -y install pdns-recursor
# configure pdns-recursor
cat << FILE > /etc/pdns-recursor/recursor.conf
local-address=$${instance_ip}
allow-from= ${vpc_cidr}, 127.0.0.0/8, 172.17.0.0/16
dont-query=127.0.0.0/8, 192.168.0.0/16, 172.16.0.0/12, ::1/128, fe80::/10
forward-zones-recurse=${dns_zone}=169.254.169.253
max-recursion-depth=100
security-poll-suffix=
setgid=pdns-recursor
setuid=pdns-recursor
max-negative-ttl=10
FILE

# create docker_resolv.conf file
cat << FILE > /etc/docker_resolv.conf
nameserver $${instance_ip}
FILE

# ECS Agent
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-install.html
echo "DOCKER_STORAGE_OPTIONS=\"--storage-driver=overlay2\"" >> /etc/sysconfig/docker-storage
echo ECS_CLUSTER=${ecs_cluster_id} >> /etc/ecs/ecs.config
systemctl enable --now --no-block ecs

#start pdns-recursor
service pdns-recursor restart