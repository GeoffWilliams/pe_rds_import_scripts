#!/bin/bash

# The contents of this file will be used as a temporary password for the 
# pe-postgres user.  Change to suit your needs if you have high security 
# requirements 
TEMP_PASSWORD=$(cat pe-postgres_password)

# User to take dumps as - assumes this user can connect to pe-postgres using
# local ident authentication.  Modify script and/or database connection 
# properties in pg_hba.conf if this is not the case
PE_POSTGRES="pe-postgres"
SU_CMD="su $PE_POSTGRES -s /bin/bash -c"

# database to dump
DBS="console
pe-activity
pe-classifier
pe-puppetdb
pe-rbac
template1"

# Take a binary dump of each of the above databases.  Binary dumps allow 
# re-ordering of operations and offer greater flexibility over text dumps at 
# the expense of less compatibility between versions
for DB in $DBS ; do
	echo "DUMPING ${DB}"
	$SU_CMD "cd /tmp && /opt/puppet/bin/pg_dump -F c $DB" > $DB.bin_sql
done

# dump and fix users - must remove all options and flags or RDS pukes.  We also
# set a password for the pe-postgres user so that we can connect as this user 
# to perform the restore.
$SU_CMD "cd /tmp && /opt/puppet/bin/pg_dumpall --roles-only --clean" | \
	awk '{ 	\
		gsub(/ (NO)?SUPERUSER/, ""); 
		gsub(/ INHERIT/, "");
		gsub(/ (NO)?CREATEROLE/, "");
		gsub(/ (NO)?CREATEDB/, "");
		gsub(/ (NO)?REPLICATION/, "");
		print $0 \
	} ' \
	| awk '{ \
		if ($0 ~ /ALTER ROLE "pe-postgres"/) \
			gsub(";", " PASSWORD \x27'$TEMP_PASSWORD'\x27;"); \
	  	print \
	}' > users.sql

# give pe-admin role magic powers- as much as its allowed by amazon
echo "GRANT rds_superuser TO \"pe-postgres\";" >> users.sql
