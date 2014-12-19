# == Class: puppet_enterprise
#
# Full description of class puppet_enterprise here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { puppet_enterprise:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2013 Your name here, unless otherwise noted.
#
class puppet_enterprise (
  $certificate_authority_host      = undef,
  $certificate_authority_port      = 8140,

  $puppet_master_host              = undef,
  $puppet_master_port              = undef,

  $console_host                    = undef,
  $console_port                    = $puppet_enterprise::params::console_ssl_listen_port,

  # In PE 3.4, it is assumed that the services api and dashboard are running on
  # the same host as the console. At this time parameters are provided for
  # changing the service ports for the api and dashboard, but not for changing
  # either the composite api host or individual service host(s).

  $api_port                        = $puppet_enterprise::params::console_services_api_ssl_listen_port,
  $dashboard_port                  = $puppet_enterprise::params::dashboard_ssl_listen_port,

  $puppetdb_host                   = undef,
  $puppetdb_port                   = $puppet_enterprise::params::puppetdb_ssl_listen_port,

  $database_host                   = undef,
  $database_port                   = $puppet_enterprise::params::database_port,

  $dashboard_database_name         = 'console',
  $dashboard_database_user         = 'console',
  $dashboard_database_password     = undef,

  $puppetdb_database_name          = 'pe-puppetdb',
  $puppetdb_database_user          = 'pe-puppetdb',
  $puppetdb_database_password      = undef,

  $classifier_database_name        = 'pe-classifier',
  $classifier_database_user        = 'pe-classifier',
  $classifier_database_password    = undef,
  $classifier_url_prefix           = $puppet_enterprise::params::classifier_url_prefix,

  $activity_database_name          = 'pe-activity',
  $activity_database_user          = 'pe-activity',
  $activity_database_password      = undef,
  $activity_url_prefix             = $puppet_enterprise::params::activity_url_prefix,

  $rbac_database_name              = 'pe-rbac',
  $rbac_database_user              = 'pe-rbac',
  $rbac_database_password          = undef,
  $rbac_url_prefix                 = $puppet_enterprise::params::rbac_url_prefix,

  $database_ssl                    = true,
  $jdbc_ssl_properties             = $puppet_enterprise::params::jdbc_ssl_properties,

  $mcollective_middleware_hosts    = $puppet_enterprise::params::activemq_brokers,
  $mcollective_middleware_port     = 61613,
  $mcollective_middleware_user     = 'mcollective',
  $mcollective_middleware_password = $puppet_enterprise::params::stomp_password,
) inherits puppet_enterprise::params {

  # ANCHORS
  # When building a complex multi-tier model, it is not known up front which
  # profiles will be deployed to a given node. However, some profiles when
  # deployed together have dependencies which must be expressed. For example,
  # the CA must be set up and configured before certificates can be requested.
  # Therefore the CA must be configured before any certificate-requiring
  # service. Since the profiles cannot express those dependencies directly
  # against each other, since they may or may not exist in a given node's
  # catalog, we instead have them express dependencies against common anchors.

  pe_anchor { 'puppet_enterprise:barrier:ca': }

  # VARIABLES
  # Several variables consumed by child classes are generated based on
  # user-specified parameters to this class. These must be set here instead of
  # in params because they are dynamic based on user specified data, and not
  # just defaults.

  if $database_ssl {
    $database_properties = $jdbc_ssl_properties
  } else {
    $database_properties = ''
  }
}
