require 'puppet_x/nmaludy/iscsi'
require 'singleton'

module PuppetX::Nmaludy::Iscsi
  # Class for caching instances
  class Cache
    include Singleton
    attr_accessor :cached_instances

    def initialize
      @cached_instances = {}
    end
  end
end
