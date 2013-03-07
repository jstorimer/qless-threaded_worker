# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'qless/threaded_worker/version'

Gem::Specification.new do |gem|
  gem.name          = "qless-threaded_worker"
  gem.version       = Qless::ThreadedWorker::VERSION
  gem.authors       = ["Jesse Storimer"]
  gem.email         = ["jesse@shopify.com"]
  gem.description   = %q{A alternate worker model for the Qless queueing library. Provides a multi-threaded worker based on Celluloid. Heavily inspired by Sidekiq.}
  gem.summary       = gem.description
  gem.homepage      = "http://github.com/Shopify/qless-threaded_worker"

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'qless', '~> 0.9.2'
  gem.add_runtime_dependency 'celluloid', '~> 0.12.4'

  gem.add_development_dependency 'rr'
end
