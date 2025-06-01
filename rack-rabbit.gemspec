# -*- encoding: utf-8 -*-
LIB = File.expand_path("lib", File.dirname(__FILE__))
$LOAD_PATH.unshift LIB unless $LOAD_PATH.include?(LIB)

require 'rack-rabbit'

Gem::Specification.new do |s|

  s.name     = "rack-rabbit"
  s.version  = RackRabbit::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors  = ["Jake Gordon"]
  s.email    = ["jakesgordon@gmail.com"]
  s.homepage = "https://github.com/jakesgordon/rack-rabbit"
  s.summary  = RackRabbit::SUMMARY

  s.has_rdoc         = false
  s.extra_rdoc_files = ["README.md"]
  s.rdoc_options     = ["--charset=UTF-8"]
  s.files            = `git ls-files `.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths    = ["lib"]
  s.licenses         = ["MIT"]

end
