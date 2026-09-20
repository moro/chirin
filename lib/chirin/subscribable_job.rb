module Chirin
  # The event payload is the job's single argument. Active Job is responsible
  # for serialization; custom event objects need an Active Job serializer.
  module SubscribableJob
    def self.included(base)
      base.extend(ClassMethods)
    end

    class JobSubscriber
      def initialize(job_class)
        @job_class = job_class
      end

      def emit(event)
        @job_class.perform_later(event.fetch(:payload))
      end
    end

    module ClassMethods
      # Returns the subscriber so its owner can unsubscribe before reloading.
      # Registration is explicit: repeated calls create repeated subscriptions.
      def subscribe(event_type, reporter: Rails.event)
        filter = case event_type
        when Class
          ->(event) { event[:payload].is_a?(event_type) }
        when String, Symbol
          name = event_type.to_s
          ->(event) { event[:name] == name }
        else
          raise ArgumentError, "event_type must be a Class, String, or Symbol"
        end

        subscriber = JobSubscriber.new(self)
        reporter.subscribe(subscriber, &filter)
        subscriber
      end
    end
  end
end
