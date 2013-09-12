# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'deprecator/version'

Gem::Specification.new do |spec|
  spec.name          = "deprecator"
  spec.version       = Deprecator::VERSION
  spec.authors       = ["Vasily Fedoseyev"]
  spec.email         = ["vasilyfedoseyev@gmail.com"]
  spec.description   = %q{Yet another library for dealing with code deprecation in ruby}
  spec.summary       = %q{Adds some beauty and structure to code deprecation, see readme}
  spec.homepage      = "http://github.com/Vasfed/deprecator"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 1.9.1'
  spec.add_dependency "is_a", "~> 0.1"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
