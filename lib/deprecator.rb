require "deprecator/version"
require 'is_a'

module Deprecator

  class DeprecatedClass
    def self.inherited cls
      ::Deprecator.strategy.class_found(cls, caller_line)
    end

    def initialize *args
      ::Deprecator.strategy.object_found(self, caller_line)
    end
  end

  module DeprecatedModule
    [:included, :extended].each{|m|
      define_singleton_method(m){|cls|
        ::Deprecator.strategy.class_found(cls, caller_line)
      }
    }

    # SMELL: initialize in module is no good, but in this case may help for some cases
    def initialize *args
      ::Deprecator.strategy.object_found(self, caller_line)
    end

    Class = DeprecatedClass
  end


  module Strategies
    class Warning
      def class_found o, where=nil, reason=nil
      end
      def object_found o, where=nil, reason=nil # deprecated class initialize
      end
      def method_found cls,name, reason, where=nil
        unless cls.methods.include?(name) # also we may place stubs there for existing methods in other strategies
          cls.define_method(name){|*args|
            warn "deprecated method called!"
          }
        end
      end
      def deprecated reason, where, args
      end
      def fixme! msg, where, args; end
      def todo! msg, where, args; end
      def not_implemented msg, where, args
      end
    end
  end
  DefaultStrategy = Strategies::Warning

  class UnknownStrategy < ArgumentError; end

  @@strategy = nil
  def self.strategy
    @@strategy ||= DefaultStrategy.new
  end

  def self.strategy= s
    case s
    when Class then return(@@strategy = s.new)
    when Symbol then
      capitalized = s.capitalize
      if Strategies.const_defined?(capitalized)
        strategy = Strategies.const_get(capitalized)
      else
        raise UnknownStrategy, s
      end
    else
      @@strategy = s
    end
  end
end

class Class
  def deprecated reason=nil, *args
    ::Deprecator.strategy.class_found(self, caller_line, reason, args)
  end

  def __on_next_method &blk
    m = self.method(:method_added)
    @method_added_stack ||= []
    @method_added_stack.push(m)
    self.define_method(:method_added, ->(name){
      super
      return if name == :method_added
      blk.call(name)
      self.define_method(:method_added, @method_added_stack.pop)
    })
  end

  def deprecated_method name, reason=nil, &blk
    unless reason
      if name.is_a?(String)
        reason = name
        name = nil
        # => take next defined method
        __on_next_method{|name|
          Deprecator.strategy.method_found(self, name, reason, caller_line)
        }
      end
    end

    name = [name] unless name.is_a?(Array)
    name.each{|n|
      Deprecator.strategy.method_found(self, name, reason, caller_line)
    }
  end
end

module Kernel
  def deprecated reason=nil, *args
    Deprecator.strategy.deprecated(reason, caller_line, args)
  end
  alias DEPRECATED deprecated

  [:fixme!, :todo!, :not_implemented].each{|method|
    define_method(method){|msg, *args| Deprecator.strategy.send(method, msg, caller_line, args) }
  }
  alias FIXME fixme!
  alias TODO todo!
  alias NOT_IMPLEMENTED not_implemented
end

DEPRECATED = Deprecator::DeprecatedModule
Deprecated = DEPRECATED unless Object.const_defined?(:Deprecated)
