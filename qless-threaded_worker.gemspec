# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'qless/threaded_worker/version'

Gem::Specification.new do |gem|
  gem.name          = "qless-threaded_worker"
  gem.version       = Qless::ThreadedWorker::VERSION
  gem.authors       = ["Jesse Storimer"]
  gem.email         = ["jesse@shopify.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'qless', '~> 0.9.2'
  gem.add_runtime_dependency 'celluloid', '~> 0.12.4'

  gem.add_development_dependency 'rr'
end
