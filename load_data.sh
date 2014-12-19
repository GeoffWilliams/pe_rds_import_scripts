#!/bin/bash
HOSTNAME=$1
ADMIN_USER="root"
SERVICE_DATABASE="postgres"
PG_RESTORE="/opt/puppet/bin/pg_restore"
PSQL="/opt/puppet/bin/psql"
AWK="/bin/awk"
PE_ADMIN_USER="pe-postgres"

# skip template0 - its a blank file
DBS="template1
console
pe-activity
pe-classifier
pe-puppetdb
pe-rbac"
if [ "$HOSTNAME" == "" ] ; then
	echo "must supply hostname (and ~/.pgpass must exist)"
else 

	$PSQL --host $HOSTNAME $SERVICE_DATABASE < users.sql
	for DB in $DBS ; do
		if [ "$DB" == "template1" ] ; then
			USER=$PE_ADMIN_USER
		else
			USER=$DB
		fi
		DUMP_FILE="${DB}.bin_sql"
		echo "processing ${DUMP_FILE}..."
		# step 1 - remove & recreate database as rds admin user based on the dump
		# file.  There's no builtin way to do this and the --no-tablespaces option
		# doesn't seem to work so tablespaces must be manually awkfooed out of the
		# way.  Use '\connect' as a record seperator and print the first record 
		# after mangling it, then exit
		$PG_RESTORE \
			--create \
			--clean \
			--section=pre-data $DUMP_FILE \
			| $AWK 'BEGIN {RS="\\\\connect"} \
				{gsub(/ TABLESPACE = "[^"]+"/, ""); print} \
				NR == 1 { exit }' \
			| $PSQL --username $ADMIN_USER --host $HOSTNAME $SERVICE_DATABASE

		# step 2 - load extensions
		$PSQL --username $PE_ADMIN_USER --host $HOSTNAME $DB --command "CREATE EXTENSION citext;"
		$PSQL --username $PE_ADMIN_USER --host $HOSTNAME $DB --command "CREATE EXTENSION plpgsql;"
		
		# step 3 - load the data as the owner of the database
		$PG_RESTORE \
			-d $DB \
			--username $USER \
			--host $HOSTNAME \
			--no-tablespaces \
			$DUMP_FILE
	done
fi
