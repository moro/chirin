require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "active_job/railtie"
require "chirin"

module ChirinSample
  class Application < Rails::Application
    config.load_defaults 8.1
    config.root = File.expand_path("..", __dir__)
    config.eager_load = false
    config.enable_reloading = false
    config.secret_key_base = "chirin-test-only-secret"
    config.logger = Logger.new(File::NULL)
    config.hosts = ["www.example.com"]
    config.active_support.deprecation = :raise
    config.action_controller.allow_forgery_protection = false
    config.action_dispatch.show_exceptions = :none
    config.active_job.queue_adapter = :test
    config.action_mailer.delivery_method = :test
    config.action_mailer.perform_deliveries = true
    config.action_mailer.default_url_options = { host: "www.example.com" }

    # Test-only app without reloading. Production reload ownership is separate.
    config.after_initialize do
      ActiveJob::Serializers.add_serializers(Events::OrderPlacedSerializer)
      OrderReceiptJob.subscribe(Events::OrderPlaced)
      Rails.event.raise_on_error = true
    end
  end
end
