require 'puppet_x/nmaludy/iscsi/type_utils.rb'

Puppet::Type.newtype(:iscsi_target) do
  desc 'Manages iSCSI targets'
  
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
    desc 'WWN of the target'

    validate do |value|
      PuppetX::Nmaludy::Iscsi::TypeUtils.validate_string(name, value)
    end
  end

  newparam(:fabric) do
    desc <<-EOS
      Name of the fabric to create the target on. Lots of options here, so we're
      not going to validate against an enum or anything. We will default to iscsi.
    EOS

    defaultto 'iscsi'

    validate do |value|
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
end
