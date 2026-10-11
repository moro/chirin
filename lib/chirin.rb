require "active_support"
require "active_support/event_reporter"
require "active_job"
require_relative "chirin/version"
require_relative "chirin/event"
require_relative "chirin/event_serializer"
require_relative "chirin/event_filter"
require_relative "chirin/subscribable_job"
require_relative "chirin/subscribable_mailer"

ActiveJob::Serializers.add_serializers(Chirin::EventSerializer)
