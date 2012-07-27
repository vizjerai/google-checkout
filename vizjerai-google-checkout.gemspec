# -*- encoding: utf-8 -*-
require File.expand_path('../lib/google-checkout/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Peter Elmore", "Geoffrey Grosenbach", "Matt Lins", "Steel Fu", "Andrew Assarattanakul"]
  gem.email         = ["assarata@gmail.com"]
  gem.description   = %q{An experimental library for sending payment requests to Google Checkout.}
  gem.summary       = %q{Google Checkout}
  gem.homepage      = "https://github.com/vizjerai/google-checkout"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "vizjerai-google-checkout"
  gem.require_paths = ["lib"]
  gem.version       = GoogleCheckout::VERSION

  gem.add_dependency 'activesupport', '>= 2.3.0'
  gem.add_dependency 'money', '>= 2.3.0'
  gem.add_dependency 'nokogiri'
  gem.add_dependency 'builder'

  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'rubygems-bundler'
  gem.add_development_dependency 'rspec'
end
