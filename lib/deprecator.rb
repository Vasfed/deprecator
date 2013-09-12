require "deprecator/version"
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


  module Strategy
    class Warning
      def msg msg, where=nil
        warn "[DEPRECATED] #{msg}"
      end

      def class_found o, where=nil, reason=nil, args=nil
        # msg(if reason
        #   reason.gsub(/%{cls}/, o)
        # else
        #   "#{o} is deprecated!"
        # end, where)
      end

      def object_found o, where=nil, reason=nil # deprecated class initialize
        msg "deprecated class #{o.class} instantiated", where
      end

      # this is not entry point
      def method_called cls,name,reason=nil,where,defined_at
        msg "method #{name} is deprecated. Called from #{caller_line}"
      end

      def method_found cls,name, reason, where=nil
        this = self
        unless cls.method_defined?(name) # also we may place stubs there for existing methods in other strategies
          cls.send :define_method, name, ->(*args){
            this.method_called cls,name,reason,caller_line,where
          }
        else
          method = cls.instance_method(name)
          cls.send :define_method, name, ->(*args){
            this.method_called cls,name,reason,caller_line,where
            method.bind(self).call(*args)
          }
        end
      end

      def deprecated reason=nil, where=caller_line, args=nil
        where =~ /in `(.+)'$/
        method_name = $1 || '<unknown>'
        reason ||= "%{method} is deprecated!"
        reason.gsub!('%{method}', method_name)
        msg reason, where
      end
      def fixme! msg, where, args
        # warn "[FIXME] #{msg} @ #{where}"
      end
      def todo! msg, where, args; end
      def not_implemented msg, where, args
        raise NotImplemented, "method at #{where} called from #{caller_line(2)}"
      end
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
        strategy = Strategy.const_get(capitalized)
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
    unless reason
      if !name || name.is_a?(String)
        reason = name
        name = nil
        # => take next defined method
        __on_next_method{|name|
          Deprecator.strategy.method_found(self, name, reason, caller_line)
        }
        return
      end
    end

    name = [name] unless name.is_a?(Array)
    name.each{|n|
      Deprecator.strategy.method_found(self, n, reason, caller_line)
    }
  end
end

module Kernel
  def deprecated reason=nil, *args
    Deprecator.strategy.deprecated(reason, caller_line, args)
  end
  alias DEPRECATED deprecated

  [:fixme!, :todo!, :not_implemented].each{|method|
    define_method(method){|msg=nil, *args| Deprecator.strategy.send(method, msg, caller_line, args) }
  }
  alias FIXME fixme!
  alias TODO todo!
  alias NOT_IMPLEMENTED not_implemented
end

DEPRECATED = Deprecator::Deprecated
Deprecated = DEPRECATED unless Object.const_defined?(:Deprecated)
