require 'puppet/property/boolean'
require 'puppet_x/nmaludy/iscsi/type_utils.rb'

def validate_backstore_type(param, type_val, type_list)
  raise ArgumentError, "#{param} is only valid when 'type' is one of #{type_list}, given: #{type_val}" unless type_list.include?(type_val.to_s)
end

Puppet::Type.newtype(:iscsi_target_backstore) do
  desc <<-EOS
    Manages iSCSI Storage Object backstore: block, fileio (tested), pscsi, ramdisk
    # FileIO
    Creates a FileIO storage object. If "file_or_dev" is a path
    to a regular file to be used as backend, then the "size"
    parameter is mandatory. Else, if "file_or_dev" is a path to a
    block device, the size parameter must be omitted. If
    present, "size" is the size of the file to be used, "file"
    the path to the file or "dev" the path to a block device. The
    "write_back" parameter is a boolean controlling write
    caching. It is enabled by default. The "sparse" parameter is
    only applicable when creating a new backing file. It is a
    boolean stating if the created file should be created as a
    sparse file (the default), or fully initialized.
  EOS

  ensurable do
    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end

    defaultto :present
  end

  # namevar is always a parameter
  newparam(:name, namevar: true) do
    desc 'Full path of the backstore'

    munge do |value|
      match = value.match(%r{^\/backstores\/(.*)\/(.*)$})
      if match
        @resource[:type] = match.captures[0]
        @resource[:object_name] = match.captures[1]
      end
      value
    end

    validate do |value|
      PuppetX::Nmaludy::Iscsi::TypeUtils.validate_string(name, value)
    end
  end

  newproperty(:object_name) do
    desc 'Name of backstore object'

    isrequired
  end

  newproperty(:type) do
    desc 'Type of backstore device to create.'

    isrequired

    newvalues(:block, :fileio, :pscsi, :ramdisk)
  end

  newparam(:dev) do
    desc <<-EOS
      Used with: block, fileio. pscsi

      fileio
      ======
      If "dev" is a path to a regular file to be used as backend, then the "size"
      parameter is mandatory. Else, if "dev" is a path to a
      block device, the size parameter must be omitted. If
      present, "size" is the size of the file to be used, "file"
      the path to the file or "dev" the path to a block device
    EOS

    validate do |value|
      validate_backstore_type(name, @resource[:type], ['block', 'fileio', 'pscsi'])
      PuppetX::Nmaludy::Iscsi::TypeUtils.validate_string(name, value)
    end
  end

  newparam(:size) do
    desc <<-EOS
      Used with: fileio, ramdisk
      SIZE SYNTAX
      ===========
      - If size is an int, it represents a number of bytes.
      - If size is a string, the following units can be used:
          - B or no unit present for bytes
          - k, K, kB, KB for kB (kilobytes)
          - m, M, mB, MB for MB (megabytes)
          - g, G, gB, GB for GB (gigabytes)
          - t, T, tB, TB for TB (terabytes)
      EOS

    validate do |value|
      validate_backstore_type(name, @resource[:type], ['fileio', 'ramdisk'])
      unless value.is_a?(String) || value.is_a?(Integer)
        raise ArgumentError, "#{name} is expected to be an String or Integer, given: #{value.class.name}"
      end
      return if value.is_a?(Integer)

      unless value.downcase =~ %r{^[0-9]+(k|kb|m|mb|g|gb|t|tb)$}
        raise ArgumentError, "#{name} when being used as a string is expected to be a number followed by (k, K, kB, KB, m, M, mB, MB, g, G, gB, GB, t, T, tB, TB), given: #{value}"
      end
    end
  end

  newparam(:write_back, boolean: true, parent: Puppet::Property::Boolean) do
    desc <<-EOS
      Used with: fileio
      Should this use write caching or not. Targetcli says this is enabled by default
      We're going to accept the targetcli defaults, and that is what will be used
      if this parameter is not specified
    EOS

    validate do |value|
      validate_backstore_type(name, @resource[:type], ['fileio'])
      super(value)
    end
  end

  newparam(:sparse, boolean: true, parent: Puppet::Property::Boolean) do
    desc <<-EOS
      Used with: fileio
      The "sparse" parameter is only applicable when creating a new backing file. It is a
      boolean stating if the created file should be created as a
      sparse file (the default), or fully initialized.
      We're going to accept the targetcli defaults, and that is what will be used
      if this parameter is not specified
    EOS

    validate do |value|
      validate_backstore_type(name, @resource[:type], ['fileio'])
      super(value)
    end
  end

  newparam(:wwn) do
    desc <<-EOS
      Used with: block, fileio, ramdisk
      World Wide Name of the backstore
    EOS

    validate do |value|
      validate_backstore_type(name, @resource[:type], ['block', 'fileio', 'ramdisk'])
      PuppetX::Nmaludy::Iscsi::TypeUtils.validate_string(name, value)
    end
  end

  newparam(:savefile) do
    desc 'File where iSCSI configurations are read from'

    defaultto '/etc/target/saveconfig.json'

    validate do |value|
      PuppetX::Nmaludy::Iscsi::TypeUtils.validate_string(name, value)
    end
  end

  validate do
    PuppetX::Nmaludy::Iscsi::TypeUtils.validate_required_attributes(self)
    msg = " when type='#{self[:type]}'"
    if self[:type] == 'fileio'
      PuppetX::Nmaludy::Iscsi::TypeUtils.validate_attribute_set(self, :file_or_dev, msg)
    elsif ['block', 'pscsi'].include?(self[:type])
      PuppetX::Nmaludy::Iscsi::TypeUtils.validate_attribute_set(self, :dev, msg)
    elsif self[:type] == 'ramdisk'
      PuppetX::Nmaludy::Iscsi::TypeUtils.validate_attribute_set(self, :size, msg)
    end
  end
end
