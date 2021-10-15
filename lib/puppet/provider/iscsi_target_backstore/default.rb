require 'puppet/provider/iscsi'

Puppet::Type.type(:iscsi_target_backstore).provide(:default, parent: Puppet::Provider::Iscsi) do
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
    data = read_savefile
    Puppet.debug("Targetcli data: #{data}")
    data.fetch('storage_objects', []).each do |storage_object|
      instance = {
        ensure: :present,
        name: "/backstores/#{storage_object['plugin']}/#{storage_object['name']}",
        type: storage_object['plugin'].to_sym,
        object_name: storage_object['name'],
      }
      # the following properties share the same name in our resource as in the config
      props = ['dev', 'size', 'write_back', 'sparse', 'wwn']
      props.each do |prop|
        instance[prop.to_sym] = storage_object[prop] if storage_object.key?(prop)
      end
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
    type_s = resource[:type].to_s
    case resource[:ensure]
    when :absent
      targetcli("backstores/#{type_s}", 'delete', resource[:object_name])
    when :present
      if cached_instance[:ensure] == :present
        # previous state was present, that means we're updating something
        # targetcli doesn't have a way to update these properties in-place so we
        # have to recreate the target
        targetcli("backstores/#{type_s}", 'delete', resource[:object_name])
        # when we delete above, this deletes things like LUNs, so we want to make
        # sure those caches get re-read when applying the resources
        clear_all_cached_instances_all_types
      end
      cmd = ["backstores/#{type_s}", 'create', resource[:object_name]]
      if type_s == 'fileio'
        # required
        cmd << "file_or_dev=#{resource[:dev]}"
        # optional
        [:size, :write_back, :sparse, :wwn].each do |param|
          cmd << "#{param}=#{resource[param]}" unless resource[param].nil?
        end
      end
      targetcli(cmd)
    end
    saveconfig
  end
end
