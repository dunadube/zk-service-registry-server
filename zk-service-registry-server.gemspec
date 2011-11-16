# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "zk-service-registry-server/version"

Gem::Specification.new do |s|
  s.name        = "zk-service-registry-server"
  s.version     = Zk::Service::Registry::Server::VERSION
  s.authors     = ["Stefan Huber"]
  s.email       = ["stefan.huber@friendscout24.de"]
  s.homepage    = ""
  s.summary     = %q{Contains the ZooKeeper Server}
  s.description = %q{Bundles the ZooKeeper Server JAVA Classes}

  s.rubyforge_project = "zk-service-registry-server"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
