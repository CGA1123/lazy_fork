# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lazy_fork/version'

Gem::Specification.new do |spec|
  spec.name          = "lazy_fork"
  spec.version       = LazyFork::VERSION
  spec.authors       = ["Christian Gregg"]
  spec.email         = ["c_arlt@hotmail.com"]

  spec.summary       = %q{A gem for lazy forkers.}
  spec.homepage      = "https://github.com/CGA1123/lazy_fork"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.executables   = ["lazy_fork"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
