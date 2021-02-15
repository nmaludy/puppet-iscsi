require 'puppet_x/nmaludy/iscsi'
require 'singleton'

module PuppetX::Nmaludy::Iscsi
  # Class for caching instances
  class Cache
    include Singleton
    attr_accessor :cached_instances
    attr_accessor :cached_configs

    def initialize
      @cached_instances = {}
      @cached_configs = {}
    end
  end
end
