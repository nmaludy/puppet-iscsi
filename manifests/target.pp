class iscsi::target (
  String  $savefile                = $iscsi::target_savefile,
  Boolean $package_manage          = $iscsi::target_package_manage,
  String  $package_name            = $iscsi::target_package_name,
  String  $package_ensure          = $iscsi::target_package_ensure,
  Boolean $service_manage          = $iscsi::target_service_manage,
  String  $service_name            = $iscsi::target_service_name,
  String  $service_ensure          = $iscsi::target_service_ensure,
  Boolean $service_enable          = $iscsi::target_service_enable,
  Boolean $firewall_manage         = $iscsi::target_firewall_manage,
  String  $firewall_service_name   = $iscsi::target_firewall_service_name,
  String  $firewall_service_ensure = $iscsi::target_firewall_service_ensure,
  String  $firewall_service_zone   = $iscsi::target_firewall_service_zone,
) inherits iscsi {
  if $package_manage {
    package { $package_name:
      ensure => $package_ensure,
    }
    Package[$package_name] -> Iscsi_target_backstore<| |>
  }
  if $service_manage {
    service { $service_name:
      ensure => $service_ensure,
      enable => $service_enable,
    }
    Service[$service_name] -> Iscsi_target_backstore<| |>
  }
  if $firewall_manage {
    firewalld_service { $firewall_service_name:
      ensure => $firewall_service_ensure,
      zone   => $firewall_service_zone,
    }
  }

  include iscsi::target::saveconfig
}
