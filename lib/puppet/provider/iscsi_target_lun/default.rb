require 'puppet/provider/iscsi'

Puppet::Type.type(:iscsi_target_lun).provide(:default, parent: Puppet::Provider::Iscsi) do
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
      target.fetch('tpgs', []).each do |tpg|
        tpg.fetch('luns', []).each do |lun_obj|
          idx = lun_obj['index']
          instance = {
            ensure: :present,
            name: "/#{target['fabric']}/#{target['wwn']}/tpg#{tpg['tag']}/luns/lun#{idx}",
            fabric: target['fabric'],
            target: target['wwn'],
            tpg_tag: tpg['tag'],
            lun: idx,
            storage_object: lun_obj['storage_object'],
          }
          all_instances[instance[:name]] = instance
        end
      end
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
    path = "/#{resource[:fabric]}/#{resource[:target]}/tpg#{resource[:tpg_tag]}/luns/"
    case resource[:ensure]
    when :absent
      targetcli(path, 'delete', resource[:lun])
    when :present
      targetcli(path, 'create', resource[:storage_object], "lun=#{resource[:lun]}")
    end
    saveconfig
  end

  def exists?
    @property_hash = cached_instance.clone
    Puppet.info("Calling exists? on LUN: #{resource[:name]}")
    @property_hash[:ensure] == :present
  end

  # when refreshed by something, delete our instance cache so that when this instance
  # is checked for existance that we get the new state.
  # this is important if say the backing store for this LUN is recreated, it automatically
  # deletes this LUN, so any cached state we have is now invalid.
  def refresh
    Puppet.info("Calling refresh on LUN: #{resource[:name]}")
    clear_cache
    read_instance
  end
end
