#RDS Import procedure for Puppet Enterprise

Quick and dirty BASH scripts, awkfoo and procedure to load data from Puppet 
Enterprise 3.7.1+ into Amazon RDS.

##Procedure
With a little awk-foo, its possible to take advantage of the Amazon RDS 
PostgreSQL service to gain features such as multi-datacenter replication, PIT
recovery and fail-over which could potentially improve reliability in Amazon
environments.

The scripts in this repository can be used to migrate an existing puppet 
installation to Amazon RDS.  They have been tested on a fresh monolithic 
installation of puppet and perform minor tweaks on data as it is reloaded. 
YMMV with large established installations or if there have been changes to 
either Puppet or RDS.  Therefore, its advisable to perform a dry run before 
committing to a migration.

The major steps to migrate are: 
* Backup your puppetmaster(!)
Then:

1. Provision an RDS PostgreSQL server
2. Shutdown all puppet components except pe-postgresql
3. Database dump on puppet master
4. Database restore on RDS PostgreSQL server
5. Update puppetmaster to use the RDS PostgreSQL server
6. Test

### Provision an RDS postgreSQL server
From the Amazon RDS control panel, click 'Launch a DB Instance' and follow the
on-screen instructions.  Be sure to allocate adequate resources and to choose
the appropriate options for production if required.

Use the name `root` for your database admin user or you will have to modify the
loader script with your choice.

On the Advanced Settings page, leave the database name field blank to avoid 
creating an unnecessary database.

After provisioning, create a security-group for your database server and ensure
you've granted access from the puppetmaster(s) you wish to allow to connect.

### Shutdown all puppet components except pe-postgresql
To ensure data integrity, you should stop all PE daemons with the exception of
the pe-postgresql database server itself.

Investigate the `service` or `systemctl` commands to do this depending whether
your puppetmaster is using systemd or not.

### Database dump on puppet master
The Amazon RDS system doesn't allow access to the database superuser account 
and also imposes a requirement to keep its own management database on the 
server instance.  Therefore a 1:1 dump and restore from `pe-postgres` is not
possible.

Instead, individual databases need to be dumped along with the users they 
depend on.  These users need to be altered somewhat vs the `CREATE` statements
obtainted from `pg_dumpall`.  

The script will do this for you and **also sets a temporary password for the 
`pe-postgres` database user** based on the value in the file 
`pe-postgres_password` - change the contents of this file to something more
secure before creating the dump.

Once your ready, run the script `dump_puppet_dbs.sh` and the required data will
be saved to the current directory.  You need to run the script as `root` so 
that it can `su` to the `pe-postgres` user to perform the dumps.

### Database restore on RDS PostgreSQL server


### Update puppetmaster to use the RDS PostgreSQL server

### Test
Reboot the RDS instance and the puppetmaster.  When both are back up, login to 
the puppetmaster and verify that the `pe-postgresql` service is stopped.  Then
attempt to run puppet.  If puppet runs normally and your also able to login to 
the console, then your migration process was successful.  If you see errors, 
ensure your not being affected by [PE-7078](https://tickets.puppetlabs.com/browse/PE-7078),
otherwise, follow the troubleshooting steps below.

## Troubleshooting
In-case of connection errors check:

1. Connectivity from puppetmaster to port 5432 on Amazon RDS server using 
   telnet or similar
2. Connection to database using the `/opt/puppet/bin/psql` command
3. Correct database connection parameters in the following files, pay 
   particular attention to changes that could have been made by a puppet run
   or those relating to CA certificates/SSL settings: 
  * `/etc/puppetlabs/puppet-dashboard/database.yml`
  * `/etc/puppetlabs/console-services/conf.d/activity-database.conf`
  * `/etc/puppetlabs/console-services/conf.d/classifier-database.conf`
  * `/etc/puppetlabs/puppetdb/conf.d/database.ini`
  * `/etc/puppetlabs/console-services/conf.d/rbac-database.conf`
4. Turn on [SQL logging on the RDS server](http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_LogAccess.Concepts.PostgreSQL.html)
