ENV["RAILS_ENV"] = "test"
require_relative "dummy/config/application"
ChirinSample::Application.initialize!
require "rails/test_help"
ActiveRecord::Schema.verbose = false
load File.expand_path("dummy/db/schema.rb", __dir__)
