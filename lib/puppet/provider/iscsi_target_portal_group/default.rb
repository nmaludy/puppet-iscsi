require 'puppet/provider/iscsi'

Puppet::Type.type(:iscsi_target_portal_group).provide(:default, parent: Puppet::Provider::Iscsi) do
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
        instance = {
          ensure: :present,
          name: "/#{target['fabric']}/#{target['wwn']}/tpg#{tpg['tag']}",
          fabric: target['fabric'],
          target: target['wwn'],
          tpg_tag: tpg['tag'],
          attributes: tpg['attributes'],
        }
        all_instances[instance[:name]] = instance
      end
    end
    Puppet.debug("Returning all instances: #{all_instances}")
    all_instances
  end

  def read_instance(*)
    # always read all instances, don't use cache because creating iscsi targets
    # automatically creates portal groups... using cache can cause errors when trying
    # to create/modify the instance
    instances_hash = read_all_instances
    if instances_hash.key?(resource[:name])
      instance = instances_hash[resource[:name]]
      # special handling for custom ldap attributes
      if resource[:attributes]
        # only keep the attributes in the instance that are specified on the resource
        instance[:attributes].select! { |k, _v| resource[:attributes].key?(k) }
      else
        # resource didn't have attributes, so delete it
        instance.delete(:attributes)
      end
      instance
    else
      { ensure: :absent, name: resource[:name] }
    end
  end

  # this method should check resource[:ensure]
  #  if it is :present this method should create/update the instance using the values
  #  in resource[:xxx] (these are the desired state values)
  #  else if it is :absent this method should delete the instance
  #
  #  if you want to have access to the values before they were changed you can use
  #  cached_instance[:xxx] to compare against (that's why it exists)
  def flush_instance
    path = "/#{resource[:fabric]}/#{resource[:target]}/"
    case resource[:ensure]
    when :absent
      targetcli(path, 'delete', resource[:tpg_tag])
    when :present
      if cached_instance[:ensure] == :absent
        targetcli(path, 'create', resource[:tpg_tag])
      end
      if resource[:attributes]
        resource[:attributes].each do |k, v|
          # path contains a trailing /
          targetcli("#{path}tpg#{resource[:tpg_tag]}/", 'set', 'attribute', "#{k}=#{v}")
        end
      end
    end
    saveconfig
  end
end
