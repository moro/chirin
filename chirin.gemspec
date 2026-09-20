require_relative "lib/chirin/version"

Gem::Specification.new do |spec|
  spec.name = "chirin"
  spec.version = Chirin::VERSION
  spec.authors = ["moro"]
  spec.summary = "A little doorbell connecting Rails events to background jobs."
  spec.description = "Small adapters for ActiveSupport::EventReporter and Active Job."
  spec.required_ruby_version = ">= 3.2"
  spec.files = Dir["lib/**/*.rb", "README.md"]
  spec.require_paths = ["lib"]
  spec.add_dependency "activesupport", "~> 8.1.3", ">= 8.1.3.1"
  spec.add_dependency "activejob", "~> 8.1.3", ">= 8.1.3.1"
end
