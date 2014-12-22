#pe_rds_import_scripts

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
0.   Backup your puppetmaster(!)
1.   Provision an RDS PostgreSQL server
2.   Shutdown all puppet components except pe-postgresql
3.   Database dump on puppet master
4.   Database restore on RDS PostgreSQL server
5.   Update puppetmaster to use the RDS PostgreSQL server
6.   Test

### Provision an RDS postgreSQL server
### Shutdown all puppet components except pe-postgresql
### Database dump on puppet master
### Database restore on RDS PostgreSQL server
### Update puppetmaster to use the RDS PostgreSQL server
### Test

