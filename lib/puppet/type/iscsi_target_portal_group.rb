require 'puppet_x/nmaludy/iscsi/type_utils.rb'

Puppet::Type.newtype(:iscsi_target_portal_group) do
  desc 'Manages iSCSI target portal groups (TPG)'

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
    desc <<-EOS
      Full path of the TPG, this should be something like /<fabric>/<target>/tpg<tag>
    EOS

    munge do |value|
      match = value.match(%r{^\/(.*)\/(.*)\/tpg([0-9]+)$})
      if match
        @resource[:fabric] = match.captures[0]
        @resource[:target] = match.captures[1]
        @resource[:tpg_tag] = match.captures[2].to_i
      end
      value
    end

    validate do |value|
      PuppetX::Nmaludy::Iscsi::TypeUtils.validate_string(name, value)
    end
  end

  newparam(:fabric) do
    desc <<-EOS
      Name of the fabric to create the target on. Lots of options here, so we're
      not going to validate against an enum or anything. We will default to iscsi.
    EOS

    isrequired

    validate do |value|
      PuppetX::Nmaludy::Iscsi::TypeUtils.validate_string(name, value)
    end
  end

  newparam(:target) do
    desc 'Name of the target in the fabric'

    isrequired

    validate do |value|
      PuppetX::Nmaludy::Iscsi::TypeUtils.validate_string(name, value)
    end
  end

  newparam(:tpg_tag) do
    desc 'Tag of the tpg, this should be an integer'

    isrequired

    munge do |value|
      value = value.to_i if value.is_a?(String)
      value
    end

    validate do |value|
      PuppetX::Nmaludy::Iscsi::TypeUtils.validate_type(name, value, Integer)
    end
  end

  newproperty(:attributes) do
    desc 'Hash of attributes to set on the TPG'

    validate do |value|
      PuppetX::Nmaludy::Iscsi::TypeUtils.validate_type(name, value, Hash)
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
  end

  autorequire(:iscsi_target) do
    "/#{@parameters[:fabric]}/#{@parameters[:target]}"
  end
end
