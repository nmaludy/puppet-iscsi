# @summary parameters for iscsi
class iscsi::params {
  $target_savefile = '/etc/target/saveconfig.json'

  $target_package_manage = true
  $target_package_name = 'targetcli'
  $target_package_ensure = 'present'

  $target_service_manage = true
  $target_service_name = 'target'
  $target_service_ensure = 'running'
  $target_service_enable = true

  $target_firewall_manage = true
  $target_firewall_service_name = 'iscsi-target'
  $target_firewall_service_ensure = 'present'
  $target_firewall_service_zone = 'public'
}
