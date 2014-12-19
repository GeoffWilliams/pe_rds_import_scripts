#!/bin/bash
#
# change strings found in database config files from OLD_STRING to NEW_STRING 
# for puppet enterprise.
#
# *CAREFUL!* this will change ANY strings you supply!

function usage() {
	cat << EOM
	usage: $SCRIPT OLD_STRING NEW_STRING
EOM
	exit 1
}

SCRIPT=$0
OLD_STRING=$1
NEW_STRING=$2
FILES="/etc/puppetlabs/puppet-dashboard/database.yml
/etc/puppetlabs/console-services/conf.d/activity-database.conf
/etc/puppetlabs/console-services/conf.d/classifier-database.conf
/etc/puppetlabs/puppetdb/conf.d/database.ini
/etc/puppetlabs/console-services/conf.d/rbac-database.conf"

if [ "$OLD_STRING" == "" ] ; then
	usage
fi

if [ "$NEW_STRING" == "" ] ; then
	usage
fi

for FILE in $FILES ; do
	# temp file for awk to use and also our backups :)
	TEMP_FILE="${FILE}.orig"
	cp $FILE $TEMP_FILE

	awk '{ gsub("'$OLD_STRING'","'$NEW_STRING'"); print }' $TEMP_FILE > $FILE
done

