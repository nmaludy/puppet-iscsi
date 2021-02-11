# @summary Installs the targetcli package and service.
class iscsi (
  String  $target_savefile                = $iscsi::params::target_savefile,
  Boolean $target_package_manage          = $iscsi::params::target_package_manage,
  String  $target_package_name            = $iscsi::params::target_package_name,
  String  $target_package_ensure          = $iscsi::params::target_package_ensure,
  Boolean $target_service_manage          = $iscsi::params::target_service_manage,
  String  $target_service_name            = $iscsi::params::target_service_name,
  String  $target_service_ensure          = $iscsi::params::target_service_ensure,
  Boolean $target_service_enable          = $iscsi::params::target_service_enable,
  Boolean $target_firewall_manage         = $iscsi::params::target_firewall_manage,
  String  $target_firewall_service_name   = $iscsi::params::target_firewall_service_name,
  String  $target_firewall_service_ensure = $iscsi::params::target_firewall_service_ensure,
  String  $target_firewall_service_zone   = $iscsi::params::target_firewall_service_zone,
) inherits iscsi::params {
  contain iscsi::target
}
