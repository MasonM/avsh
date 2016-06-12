# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'avsh/version'
require 'rake'

Gem::Specification.new do |spec|
  spec.name          = "avsh"
  spec.version       = Avsh::VERSION
  spec.authors       = ["Mason Malone"]
  spec.email         = ["mason@masonm.org"]

  spec.summary       = 'Faster alternative to "vagrant ssh", with automatic synced folder switching'
  spec.description   = <<-EOF
  avsh ("Augmented Vagrant sSH") is a standalone script that emulates vagrant ssh, but is much
  faster and more convenient when working on synced projects. It automatically sets up SSH
  multiplexing the first time it's run, eliminating SSH connection overhead on subsequent
  invocations. In addition, it detects when you're working in a synced folder, and automatically
  switches to the corresponding directory on the guest before executing commands or starting a login
  shell.
  EOF
  spec.homepage      = "https://github.com/masonm/avsh"
  spec.license       = "MIT"

  spec.files         = FileList['lib/*.rb', 'test/test*.rb']
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "fakefs", "~> 0.8.1"
  spec.add_development_dependency "rubocop", "~> 0.40.0"
  spec.add_development_dependency "simplecov", "~> 0.11.2"
end
