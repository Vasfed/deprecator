#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.libs.push 'spec'
end


# require 'rake/extensiontask'
# Rake::ExtensionTask.new('deprecator')
# task :test => :compile

task :default => :test

task :run_example do
  load File.expand_path('../examples/example.rb', __FILE__)
end