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
    data.fetch(:storage_objects, []).each do |storage_object|
      instance = { ensure: :present }
      # backstore type has a different name in the config than the one we use
      instance[:type] = storage_object[:plugin].to_sym
      # the following properties share the same name in our resource as in the config
      props = [:name, :dev, :size, :write_back, :sparse, :wwn]
      props.each do |prop|
        instance[prop] = storage_object[prop] if storage_object.has_key?(prop)
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
      targetcli("backstores/#{type_s}", 'delete', resource[:name])
    when :present
      cmd = ["backstores/#{type_s}", 'create', resource[:name]]
      if type_s == 'fileio'
        # required
        cmd << "file_or_dev=#{resource[:dev]}"
        # optional
        [:size, :write_back, :sparse, :wwn].each do |param|
          cmd << "#{param.to_s}=#{resource[param]}" unless resource[param].nil?
        end
      end
      targetcli(cmd)
    end
    saveconfig
  end
end
