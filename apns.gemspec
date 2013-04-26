# -*- encoding: utf-8 -*-
require File.expand_path('../lib/APNS/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["William Denniss", "Paul Gebheim", "James Pozdena"]
  gem.email         = ["will@geospike.com"]
  gem.description = %q{Simple Apple push notification service gem}
  gem.summary = %q{Simple Apple push notification service gem}
  gem.homepage = %q{http://github.com/WilliamDenniss/APNS}

  gem.extra_rdoc_files = ["MIT-LICENSE"]
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "gs-apns"
  gem.require_paths = ["lib"]
  gem.version       = APNS::VERSION
  
  gem.add_development_dependency "rspec", "~> 2.6"
end
