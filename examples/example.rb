#!/usr/bin/env ruby

require 'deprecator'

class SomeClass
  deprecated

  def method1
    deprecated
  end

  def method2
    if true
      deprecated "this is deprecated when true is true"
    end
  end

  deprecated_method
  def method3
  end

  deprecated_method :method4, "%{method} is no longer here, use some other method!"
  deprecated_method [:method5, :method6], "%{method} is no longer here, use some other method!"

  def method7
    raise_deprecated # raises regardless of strategy
  end
end

obj = SomeClass.new # outputs to stderr: [DEPRECATED] deprecated class SomeClass instantiated at /Users/vasfed/work/deprecator/examples/example.rb:26:in `new'
obj.method1 # [DEPRECATED] method1 is deprecated!
obj.method2 # [DEPRECATED] this is deprecated when true is true
obj.method3 # [DEPRECATED] method method3 is deprecated. Called from /Users/vasfed/work/deprecator/examples/example.rb:28:in `<top (required)>'
obj.method4 # [DEPRECATED] method4 is no longer here, use some other method!
obj.method6 # [DEPRECATED] method6 is no longer here, use some other method!
begin
  obj.method7
rescue Deprecator::Deprecated
  puts "error raised" # guess what? :)
end
