#!/bin/bash
#
# change server host from OLD_SERVER to NEW_SERVER for puppet enterprise

function usage() {
	cat << EOM
	usage: $SCRIPT OLD_SERVER NEW_SERVER
EOM
	exit 1
}

SCRIPT=$0
OLD_SERVER=$1
NEW_SERVER=$2
FILES="/etc/puppetlabs/puppet-dashboard/database.yml
/etc/puppetlabs/console-services/conf.d/activity-database.conf
/etc/puppetlabs/console-services/conf.d/classifier-database.conf
/etc/puppetlabs/puppetdb/conf.d/database.ini
/etc/puppetlabs/console-services/conf.d/rbac-database.conf"

if [ "$OLD_SERVER" == "" ] ; then
	usage
fi

if [ "$NEW_SERVER" == "" ] ; then
	usage
fi

for FILE in $FILES ; do
	# temp file for awk to use and also our backups :)
	TEMP_FILE="${FILE}.orig"
	cp $FILE $TEMP_FILE

	awk '{ gsub("'$OLD_SERVER'","'$NEW_SERVER'"); print }' $TEMP_FILE > $FILE
done

