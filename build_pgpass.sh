#!/bin/bash
function update_pgpass() {
	USERNAME=$1
	PASSWORD=$2
	DATABASE=$3

	LINE="${HOST}:*:${DATABASE}:${USERNAME}:${PASSWORD}"
	echo $LINE >> ~/.pgpass 

	LINE="${HOST}:*:${SERVICE_DATABASE}:${USERNAME}:${PASSWORD}"
        echo $LINE >> ~/.pgpass
}

TEMP_PASSWORD=$(cat pe-postgres_password)
HOST=$1
SERVICE_DATABASE="postgres"
if [ "$HOST" == "" ] ; then
	echo "must supply host"
	exit 1
fi
echo "stealing passwords from puppet"
#console
USERNAME=$(awk '/username/ {gsub(/\x27/,"", $2) ; print $2}' /etc/puppetlabs/puppet-dashboard/database.yml)
PASSWORD=$(awk '/password/ {gsub(/\x27/,"", $2) ; print $2}' /etc/puppetlabs/puppet-dashboard/database.yml)
DATABASE=$(awk '/database/ {gsub(/\x27/,"", $2) ; print $2}' /etc/puppetlabs/puppet-dashboard/database.yml | head -1)
update_pgpass $USERNAME $PASSWORD $DATABASE

#pe-activity
USERNAME=$(awk '/user/ {gsub(/[",]/,"", $2) ; print $2}' /etc/puppetlabs/console-services/conf.d/activity-database.conf)
PASSWORD=$(awk '/password/ {gsub(/[",]/,"", $2) ; print $2}' /etc/puppetlabs/console-services/conf.d/activity-database.conf)
DATABASE=$(awk '/subname/ {match($2, /\/\/[^\/\?]+\/([^\?]+)/, a) ; print a[1]}' /etc/puppetlabs/console-services/conf.d/activity-database.conf)
update_pgpass $USERNAME $PASSWORD $DATABASE

#pe-classifier
USERNAME=$(awk '/user/ {gsub(/[",]/,"", $2) ; print $2}' /etc/puppetlabs/console-services/conf.d/classifier-database.conf)
PASSWORD=$(awk '/password/ {gsub(/[",]/,"", $2) ; print $2}' /etc/puppetlabs/console-services/conf.d/classifier-database.conf)
DATABASE=$(awk '/subname/ {match($2, /\/\/[^\/\?]+\/([^\?]+)/, a) ; print a[1]}' /etc/puppetlabs/console-services/conf.d/classifier-database.conf)
update_pgpass $USERNAME $PASSWORD $DATABASE

#pe-puppetdb
USERNAME=$(awk '/^username/ {print $3}' /etc/puppetlabs/puppetdb/conf.d/database.ini)
PASSWORD=$(awk '/^password/ {print $3}' /etc/puppetlabs/puppetdb/conf.d/database.ini)
DATABASE=$(awk '/subname/ {match($3, /\/\/[^\/\?]+\/([^\?]+)/, a) ; print a[1]}' /etc/puppetlabs/puppetdb/conf.d/database.ini)
update_pgpass $USERNAME $PASSWORD $DATABASE

#pe-rbac
USERNAME=$(awk '/user/ {gsub(/[",]/,"", $2) ; print $2}' /etc/puppetlabs/console-services/conf.d/rbac-database.conf)
PASSWORD=$(awk '/password/ {gsub(/[",]/,"", $2) ; print $2}' /etc/puppetlabs/console-services/conf.d/rbac-database.conf)
DATABASE=$(awk '/subname/ {match($2, /\/\/[^\/\?]+\/([^\?]+)/, a) ; print a[1]}' /etc/puppetlabs/console-services/conf.d/rbac-database.conf)
update_pgpass $USERNAME $PASSWORD $DATABASE

#pe-postgres - doesn't have a password by default, set one now and we will NULL it after loading data
update_pgpass pe-postgres $TEMP_PASSWORD "*"

chmod 600 ~/.pgpass
