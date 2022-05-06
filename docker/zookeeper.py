import os
import requests
import boto3
import logging as logger
from pathlib import Path
from configparser import ConfigParser

DEFAULT_SERVER = '1=localhost:2888:3888;2181'

# Get the environment variables
def get_config_env():
    ZOO_DATA_DIR = os.environ.get('ZOO_DATA_DIR')
    ZOO_DATA_LOG_DIR = os.environ.get('ZOO_CONF_DIR')
    ZOO_TICK_TIME = os.environ.get('ZOO_TICK_TIME', 2000)
    ZOO_INIT_LIMIT = os.environ.get('ZOO_INIT_LIMIT', 5)
    ZOO_SYNC_LIMIT = os.environ.get('ZOO_SYNC_LIMIT', 2)
    ZOO_AUTOPURGE_SNAPRETAINCOUNT = os.environ.get('ZOO_AUTOPURGE_SNAPRETAINCOUNT', 3)
    ZOO_AUTOPURGE_PURGEINTERVAL = os.environ.get('ZOO_AUTOPURGE_PURGEINTERVAL', 0)
    ZOO_MAX_CLIENT_CNXNS = os.environ.get('ZOO_MAX_CLIENT_CNXNS', 60)
    ZOO_STANDALONE_ENABLED = os.environ.get('ZOO_STANDALONE_ENABLED', 'false')
    ZOO_ADMINSERVER_ENABLED = os.environ.get('ZOO_ADMINSERVER_ENABLED', 'true')
    ZOO_RECONFIG = os.environ.get('ZOO_RECONFIG', False)
    ZOO_SKIPACL = os.environ.get('ZOO_SKIPACL', False)
    ZOO_ELECT_PORT_RETRY = os.environ.get('ZOO_ELECT_PORT_RETRY', False)

    config_object = {
        "dataDir": ZOO_DATA_DIR,
        "dataLogDir": ZOO_DATA_LOG_DIR,
        "tickTime": ZOO_TICK_TIME,
        "initLimit": ZOO_INIT_LIMIT,
        "syncLimit": ZOO_SYNC_LIMIT,
        "autopurge.snapRetainCount": ZOO_AUTOPURGE_SNAPRETAINCOUNT,
        "autopurge.purgeInterval": ZOO_AUTOPURGE_PURGEINTERVAL,
        "maxClientCnxns": ZOO_MAX_CLIENT_CNXNS,
        "standaloneEnabled": ZOO_STANDALONE_ENABLED,
        "admin.enableServer": ZOO_ADMINSERVER_ENABLED,
    }

    ZOO_SERVERS = os.environ.get('ZOO_SERVERS', DEFAULT_SERVER)
    if ZOO_SERVERS:
        for server in ZOO_SERVERS.split(' '):
            server = server.split("=")
            config_object["server.{}".format(server[0])] = server[1]

    ZOO_4LW_COMMANDS_WHITELIST = os.environ.get('ZOO_4LW_COMMANDS_WHITELIST', False)
    if ZOO_4LW_COMMANDS_WHITELIST:
        config_object['4lw.commands.whitelist'] = ZOO_4LW_COMMANDS_WHITELIST

    if ZOO_RECONFIG:
        config_object['reconfigEnabled'] = ZOO_RECONFIG

    if ZOO_SKIPACL:
        config_object['skipACL'] = ZOO_SKIPACL

    if ZOO_ELECT_PORT_RETRY:
        config_object['electionPortBindRetry'] = ZOO_ELECT_PORT_RETRY

    return config_object


# Write the zookeeper config in the container
def write_config():
    ZOO_CONF_DIR = os.environ.get('ZOO_CONF_DIR')
    config_object = ConfigParser()
    config_object.optionxform=str # Preserve the case
    config_object['DEFAULT'] = get_config_env()
    # Create the file
    logger.info("Creating the config file (zoo.cfg).")
    config = Path('{}/zoo.cfg'.format(ZOO_CONF_DIR))
    config.touch(exist_ok=True)
    # Write to the file
    with open('{}/zoo.cfg'.format(ZOO_CONF_DIR), 'w') as conf:
        logger.info("Writing the contents of the config file.")
        config_object.write(conf)


# Get the hosted zone, IP and the affected domain
def write_myid(myid):
    ZOO_DATA_DIR = os.environ.get('ZOO_DATA_DIR')
    # Create the file
    logger.info("Creating the config file (myid).")
    config = Path('{}/myid'.format(ZOO_DATA_DIR))
    config.touch(exist_ok=True)
    # Write to the file
    with open('{}/myid'.format(ZOO_DATA_DIR), 'w') as conf:
        logger.info("Writing the contents of the config file.")
        conf.write(myid)


# Get myid from using the current subnet
def get_myid():
    private_ip = requests.get(os.environ['ECS_CONTAINER_METADATA_URI_V4'], timeout=0.01).json()['Networks'][0]['IPv4Addresses'][0]
    subnet = private_ip.split('.')[2]
    return (private_ip, subnet)


# Get the domain by supplying myid
def get_domain(myid):
    ZOO_SERVERS = os.environ.get('ZOO_SERVERS', DEFAULT_SERVER)
    for server in ZOO_SERVERS.split(' '):
        server = server.split('=')
        if server[0] == myid:
            return server[1].split(':')[0]


# Update the R53 DNS of the specific hosted zone
def update_dns(domain, ip):
    ZOO_HOSTED_ZONE = os.environ.get('ZOO_HOSTED_ZONE', False)
    if not ZOO_HOSTED_ZONE:
        exit('ZOO_HOSTED_ZONE is not defined')
    logger.info("Updating the dns in route53.")
    r53 = boto3.client('route53')
    try:
        r53.change_resource_record_sets(
            HostedZoneId=ZOO_HOSTED_ZONE,
            ChangeBatch={
                "Comment": "Update record to reflect new IP address of zookeeper endpoint",
                "Changes": [
                    {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": domain,
                            "Type": "A",
                            "TTL": 30,
                            "ResourceRecords": [
                                {
                                    "Value": ip
                                }
                            ]
                        }
                    }
                ]
            }
        )
    except Exception as e:
        logger.error("Error: {}".format(str(e)))


def main():
    ip, myid = get_myid()
    domain = get_domain(myid)
    write_myid(myid)
    update_dns(domain, ip)
    write_config()


if __name__ == '__main__':
    main()
