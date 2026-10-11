module Chirin
  # Passes the event payload as the mailer action's single argument.
  # Action Mailer / Active Job own delivery and serialization.
  module SubscribableMailer
    def self.included(base)
      base.extend(ClassMethods)
    end

    class MailerSubscriber
      def initialize(mailer_class, action)
        @mailer_class = mailer_class
        @action = action
      end

      def emit(event)
        @mailer_class.public_send(@action, event.fetch(:payload)).deliver_later
      end
    end

    module ClassMethods
      # Returns the subscriber so the owner can unsubscribe before reloading.
      def subscribe(action, event_type, reporter: Rails.event)
        filter = EventFilter.for(event_type)
        unless action_methods.include?(action.to_s)
          raise ArgumentError, "unknown mailer action: #{action}"
        end

        subscriber = MailerSubscriber.new(self, action)
        reporter.subscribe(subscriber, &filter)
        subscriber
      end
    end
  end
end
