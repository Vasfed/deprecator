# everything that goes outside of Deprecator namespace - goes here

class Module
  include Deprecator::ClassClassMethods
end

class Class
  include Deprecator::ClassClassMethods
end

module Kernel
  def deprecated reason=nil, *args
    ::Deprecator.strategy.plain_deprecated(reason, caller_line, args)
  end
  def raise_deprecated reason=nil, *args
    raise ::Deprecator::Deprecated, reason, *args
  end
  alias DEPRECATED deprecated

  [:fixme!, :todo!, :not_implemented].each{|method|
    define_method(method){|msg=nil, *args| Deprecator.strategy.send(method, msg, caller_line, args) }
  }
  alias FIXME fixme!
  alias TODO todo!
  alias NOT_IMPLEMENTED not_implemented
end

DEPRECATED = Deprecator::DeprecatorModule
Deprecated = DEPRECATED unless Object.const_defined?(:Deprecated)
