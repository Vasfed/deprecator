require "deprecator/version"
require "deprecator/strategy"
require 'is_a'

module Deprecator

  class DeprecatedClass
    def self.inherited cls
      cls.extend(Deprecated)
    end
  end

  module Deprecated
    def self.included cls
      cls.extend self
    end

    def self.extended cls
      ::Deprecator.strategy.class_found(cls, caller_line)
      cls.send :include, InstanceMethods
    end

    module InstanceMethods
      # SMELL: initialize in module is no good, but in this case may help for some cases
      def initialize *args
        ::Deprecator.strategy.object_found(self, caller_line)
      end
    end
    Class = DeprecatedClass
  end


  module ClassClassMethods
    def deprecated reason=nil, *args
      ::Deprecator.strategy.class_found(self, caller_line, reason, args)
    end

    def __on_next_method &blk
      @method_added_stack ||= []
      if self.respond_to?(:method_added) || @method_added_stack.size > 0
        m = self.method(:method_added)
        @method_added_stack.push(m)
      end

      define_singleton_method(:method_added, ->(name){
        return if name == :method_added
        super(name)
        old = @method_added_stack.pop
        if old
          define_singleton_method(:method_added, old)
        else
          class <<self; remove_method(:method_added); end
        end
        blk.call(name)
      })
    end

    def deprecated_method name=nil, reason=nil, &blk
      where = caller_line
      unless reason
        if !name || name.is_a?(String)
          reason = name
          name = nil
          # => take next defined method
          __on_next_method {|name|
            Deprecator.strategy.method_found(self, name, reason, where)
          }
          return
        end
      end

      name = [name] unless name.is_a?(Array)
      name.each{|n|
        Deprecator.strategy.method_found(self, n, reason, where)
      }
    end
  end

  DefaultStrategy = Strategy::Warning

  class UnknownStrategy < ArgumentError; end
  class NotImplemented < RuntimeError; end

  @@strategy = nil
  def self.strategy
    @@strategy ||= DefaultStrategy.new
  end

  def self.strategy= s
    case s
    when Class then return(@@strategy = s.new)
    when Symbol then
      capitalized = s.capitalize
      if Strategy.const_defined?(capitalized)
        self.strategy = Strategy.const_get(capitalized)
      else
        raise UnknownStrategy, s
      end
    else
      @@strategy = s
    end
  end
end



require "deprecator/core_ext"
