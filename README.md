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

0. Backup your puppetmaster(!)
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

Once all services are shutdown, disable the puppet agent to prevent it changing
configuration files back to previous values:

`puppet agent --disable`

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

After the database has been dumped, you have no further use for the vendored 
`pe-postgres` installation so it should be shutdown and de-activated to stop it
starting on boot and potentially contaminating your testing.

### Database restore on RDS PostgreSQL server
You would normally restore data as the superuser but this account isn't 
available to you on RDS and you will get permission errors if you try to use 
the RDS admin user you created as it isn't a *true* superuser.

Therefore, each database needs to be restored as *itself*.

#### Preparation
You must prepare the system to connect to the various puppet databases.  This
is achieved by using the [`.pgpass` authentication mechanism](https://wiki.postgresql.org/wiki/Pgpass) 
built into Postgres. 

The files listed in the troubleshooting section contain all of the required 
account details and these can be munged into a suitable `.pgpass` file by 
running the script `build_pgpass.sh`.  The script takes one argument - the name
of the RDS server to connect to.

Run the script and then edit the resulting `~/.pgpass` file to add in the 
details of the RDS admin account you created when provisioning the instance.

See link above for details of the `.pgpass` file format.

#### Import

You should now be able to load data into the RDS instance with the 
`load_data.sh` script.  This script takes one argument - the hostname of the 
RDS instance.

You will find that you get errors and warnings when running the script.  Most
of these are harmless but you should diligently check the output of the load 
process to ensure there's nothing more sinister in there.  See file 
`sample_load_output.txt` for an example of a successful load.

If you are asked to type passwords at any time when running the script, then 
something is wrong with your `.pgpass` file or you are experiencing 
connectivity problems.  Refer to notes under troubleshooting in this case.

### Update puppetmaster to use the RDS PostgreSQL server
Once the data has been loaded, the puppetmaster needs to be configured for the
new database server by updating:

**Connection settings in configuration files**
Since the import process maintains the existing usernames and passwords, the 
only thing that needs updating is the hostname of the database server.  The 
`change_db_conf_string.sh` script will perform this change for you on each of 
the files listed in the troubleshooting section by doing a global find and 
replace:

```
./change_db_conf_string.sh NAME_OF_OLD_SERVER NAME_OF_NEW_SERVER
```

**CA authoritiy settings for Amazon RDS**
Amazon make a CA root authority file available to authenticate SSL connections.
Review the notes in the file `import_amazon_ca.sh` to ensure currancy, then 
excecute the script.

This will install the CA authority file to `/etc/puppetlabs/amazon_ca` and 
update the database connection strings to use it.  This file is kept outside
the usual `/etc/puppetlabs/puppet/ssl` directory as the file is not managed by
the puppet CA.

**Patching the `puppet_enterprise` module (only needed if JIRA unresolved)**
The current version of Puppet Enterprise (3.7.1) hardcodes the CA authority 
file [PE-7199](https://tickets.puppetlabs.com/browse/PE-7199).  To allow the 
puppetmaster to use the Amazon CA file the `puppet_enterprise` module needs to
be patched:

```
cp /opt/puppet/share/puppet/modules/puppet_enterprise/ /etc/puppetlabs/puppet/modules/ -R 
cd /etc/puppetlabs/puppet/modules/puppet_enterprise
patch -p1 < ~/pe_rds_import_scripts/puppetlabs-puppet_enterprise_jdbc_ssl_properties.diff

```

**Starting the puppet daemons**
The puppet daemons (with the exception of `pe-postgres`) can now be restarted 
or you may simply reboot.  Ensure that you have disabled the puppet agent 
before doing this or you will have to repeat the steps above after puppet 
*fixes* your puppetdb `database.ini` file.

**Connection settings in console**
Once services are restarted, login to the console and click the `
Classification` tab, then click into the `PE Infrastructure` group and click 
the `Classes` tab.

i. Change the value for `database_host` to reflect the new RDS host
ii. Add a new parameter `jdbc_ssl_properties` and set the value to:
```
?ssl=true&sslfactory=org.postgresql.ssl.jdbc4.LibPQFactory&sslmode=verify-full&sslrootcert=/etc/puppetlabs/amazon_ca/rds-ssl-ca-cert.pem
```
iii. Commit the changes

### Test
Puppet should now be fully configured for the new database server.  The first 
test of this is to enable puppet and make sure the configuration files aren't 
changed back to the old values:

```
puppet agent --enable
puppet apply -t
```

If this works succesfully, you should now do an end-to-end test by rebooting 
the puppetmaster.  If you see your database parameters being reverted instead,
then you need to investigate the linked JIRA ticket and the reason for these 
changes yourself.

If after rebooting or during the initial puppet run you see connection errors, 
ensure your not being affected by [PE-7078](https://tickets.puppetlabs.com/browse/PE-7078)
, otherwise, follow the troubleshooting steps below.

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
