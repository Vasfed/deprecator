require "deprecator/version"
require "deprecator/strategy"
require 'is_a'

module Deprecator

  class UnknownStrategy < ArgumentError; end

  class Deprecated     < RuntimeError; end
  class DeprecatedMethodCalled  < Deprecated; end
  class DeprecatedObjectCreated < Deprecated; end

  class CodeError      < RuntimeError; end
  class NotImplemented < CodeError; end
  class Fixme < CodeError; end
  class Todo < CodeError; end




  class DeprecatedClass
    def self.inherited cls
      ::Deprecator.strategy.class_found(cls, caller_line)
      # cls.extend(Deprecated::ClassMethods)
      # cls.send :include, Deprecated::InstanceMethods
    end
  end

  module DeprecatorModule
    def self.included cls
      cls.extend self
    end

    def self.extended cls
      ::Deprecator.strategy.class_found(cls, caller_line)
      # cls.send :include, InstanceMethods
      # cls.extend ClassMethods
    end

    # module ClassMethods
    # end

    # module InstanceMethods
    #   # SMELL: initialize in module is no good, but in this case may help for some cases
    #   def initialize *args
    #     ::Deprecator.strategy.object_found(self, caller_line)
    #   end
    # end
    Class = DeprecatedClass
  end


  module ClassClassMethods
    def deprecated_class reason=nil, *args
      ::Deprecator.strategy.class_found(self, caller_line, reason, args)
    end

    def __on_next_method &blk
      @method_added_stack ||= []
      if self.respond_to?(:method_added) || @method_added_stack.size > 0
        m = self.method(:method_added)
        @method_added_stack.push(m)
      end

      Deprecator._skip_next_method_added_addition!
      define_singleton_method(:method_added, ->(name){
        return if name == :method_added
        super(name)
        old = @method_added_stack.pop
        if old
          Deprecator._skip_next_method_added_addition!
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


  @@strategy = nil
  def self.strategy
    @@strategy ||= DefaultStrategy.new
  end

  def self.strategy= s
    @@strategy = case s
    when nil then DefaultStrategy.new
    when Class then s.new
    when Symbol then
      capitalized = s.capitalize
      if Strategy.const_defined?(capitalized)
        Strategy.const_get(capitalized).new
      else
        raise UnknownStrategy, s
      end
    else
      s
    end
  end

  def self.with_strategy new_strategy
    old_strategy = strategy
    self.strategy = new_strategy
    yield
    self.strategy = old_strategy
  end

  #@private
  def self._skip_next_initialize_addition!
    @_skip_next_initialize_addition = true
  end
  #@private
  def self._skip_next_initialize_addition?
    return false if !@_skip_next_initialize_addition
    remove_instance_variable :@_skip_next_initialize_addition
    return true
  end
  #@private
  def self._skip_next_method_added_addition!
    @_skip_next_method_added_addition = true
  end
  #@private
  def self._skip_next_method_added_addition?
    return false if !@_skip_next_method_added_addition
    remove_instance_variable :@_skip_next_method_added_addition
    return true
  end
end



require "deprecator/core_ext"
