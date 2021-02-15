require 'puppet/provider/iscsi'

Puppet::Type.type(:iscsi_target).provide(:default, parent: Puppet::Provider::Iscsi) do
  defaultfor kernel: 'Linux'

  commands targetcli: 'targetcli'

  # always need to define this in our implementation classes
  mk_resource_methods

  ##########################
  # private methods that we need to implement because we inherit from Puppet::Provider::Synapse

  # Read all instances of this type from the API, this will then be stored in a cache
  # We do it like this so that the first resource of this type takes the burden of
  # reading all of the data, but the following resources are all super fast because
  # they can use the global cache
  def read_all_instances
    all_instances = {}
    read_savefile.fetch('targets', []).each do |target|
      instance = {
        ensure: :present,
        name: "/#{target['fabric']}/#{target['wwn']}",
        fabric: target['fabric'],
        target: target['wwn'],
      }
      all_instances[instance[:name]] = instance
    end
    Puppet.debug("Returning all instances: #{all_instances}")
    all_instances
  end

  # this method should check resource[:ensure]
  #  if it is :present this method should create/update the instance using the values
  #  in resource[:xxx] (these are the desired state values)
  #  else if it is :absent this method should delete the instance
  #
  #  if you want to have access to the values before they were changed you can use
  #  cached_instance[:xxx] to compare against (that's why it exists)
  def flush_instance
    case resource[:ensure]
    when :absent
      targetcli("#{resource[:fabric]}/", 'delete', resource[:target])
    when :present
      targetcli("#{resource[:fabric]}/", 'create', resource[:target])
    end
    saveconfig
  end
end
