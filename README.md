# Deprecator

Yet another library for dealing with code deprecation in ruby gracefully.

Allows you to replace behavior. For example before some important release you want to revise all deprecated code that is being called by your tests (and you have near 100% coverage, don't you?) - you can just throw in a strategy, that raises an error.

The same technique also provides for ability to make deprecation messages localized via l10n/i18n etc.

## Installation

Add this line to your application's Gemfile:

```ruby
    gem 'deprecator'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install deprecator

## Usage

```ruby

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
end

obj = SomeClass.new # outputs to stderr: [DEPRECATED] deprecated class SomeClass instantiated at /Users/vasfed/work/deprecator/examples/example.rb:26:in `new'
obj.method1 # [DEPRECATED] method1 is deprecated!
obj.method2 # [DEPRECATED] this is deprecated when true is true
obj.method3 # [DEPRECATED] method method3 is deprecated. Called from /Users/vasfed/work/deprecator/examples/example.rb:28:in `<top (required)>'
obj.method4 # [DEPRECATED] method4 is no longer here, use some other method!
obj.method6 # [DEPRECATED] method6 is no longer here, use some other method!

```

changing strategies:

```ruby

Deprecator.strategy = :raise # included: warning(default), raise, raiseHard

class SomeClass
  deprecated "some reason"
  def initialize
    puts "SomeClass#initialize called"
  end
end

begin
  SomeClass.new
rescue Deprecator::Deprecated => e
  puts "caught exception #{e.class}: #{e}"
end


class CustomStrategy < Deprecator::Strategy::Base
  def object_found *args
    puts "Deprecated object created."
  end
end

Deprecator.strategy = CustomStrategy
SomeClass.new

# outputs:
# caught exception Deprecator::DeprecatedObjectCreated: some reason
# Deprecated object created.
# SomeClass#initialize called

```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
