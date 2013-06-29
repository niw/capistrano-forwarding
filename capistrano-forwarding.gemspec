lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "capistrano/forwarding/version"

Gem::Specification.new do |spec|
  spec.name          = "capistrano-forwarding"
  spec.version       = Capistrano::Forwarding::VERSION
  spec.authors       = ["Yoshimasa Niwa"]
  spec.email         = ["niw@niw.at"]
  spec.homepage      = "https://github.com/niw/capistrano-forwarding"
  spec.description   =
  spec.summary       = "Provide SSH port forwarding while deploying"

  spec.extra_rdoc_files = `git ls-files -- README*`.split($/)
  spec.files            = `git ls-files -- lib/*`.split($/) +
                          spec.extra_rdoc_files

  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "capistrano"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
