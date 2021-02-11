require 'puppet_x/nmaludy/iscsi'
require 'singleton'

# Encore module
module PuppetX::Nmaludy::Iscsi::TypeUtils
  def validate_type(attr, value, type)
    raise ArgumentError, "#{attr} is expected to be an #{type.name}, given: #{value.class.name}" unless value.is_a?(type)
  end
  module_function :validate_type

  def validate_string(attr, value)
    validate_type(attr, value, String)
  end
  module_function :validate_string

  
  def validate_attribute_set(type, attr, msg='')
    raise ArgumentError, "#{type.class.attrtype(attr)} '#{attr}' is required #{msg}" unless type[attr]
  end
  
  def validate_required_attributes(type)
    # validate all required parameters, properties and metaparams are set
    type.class.allattrs.each do |attr|
      attrclass = type.class.attrclass(attr)
      if attrclass.required? && !type[attr]
        raise ArgumentError, "#{type.class.attrtype(attr)} '#{attr}' is required"
      end
    end
  end
  module_function :validate_required_attributes
end
