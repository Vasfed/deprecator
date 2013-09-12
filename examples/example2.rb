#!/usr/bin/env ruby

require 'deprecator'

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