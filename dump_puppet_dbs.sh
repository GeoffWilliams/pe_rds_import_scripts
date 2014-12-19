#!/bin/bash

TEMP_PASSWORD=$(cat pe-postgres_password)
PG_SUPERUSER="root"
PE_POSTGRES="pe-postgres"
SU_CMD="su $PE_POSTGRES -s /bin/bash -c"

DBS="console
pe-activity
pe-classifier
pe-puppetdb
pe-rbac
template0
template1"

# dump the puppet databases
for DB in $DBS ; do
	echo "DUMPING ${DB}"
	$SU_CMD "/opt/puppet/bin/pg_dump -F c $DB" > $DB.bin_sql
done

# dump and fix users - must remove all options and flags or RDS pukes
$SU_CMD "/opt/puppet/bin/pg_dumpall --roles-only --clean" | \
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

# give pe-admin role magic powers- as much as its allowed
echo "GRANT rds_superuser TO \"pe-postgres\";" >> users.sql
