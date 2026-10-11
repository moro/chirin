require "active_job/base"
require "active_job/arguments"

module Chirin
  class EventSerializer < ActiveJob::Serializers::ObjectSerializer
    def serialize(event)
      unless event.class.name
        raise ActiveJob::SerializationError, "Chirin events must have a named class"
      end

      super(
        "event_class" => event.class.name,
        "attributes" => ActiveJob::Arguments.serialize([event.to_h])
      )
    end

    def deserialize(hash)
      event_class = hash.fetch("event_class").constantize
      unless event_class.is_a?(Class) && event_class < Data && event_class < Event
        raise ArgumentError, "event_class must be a Data class including Chirin::Event"
      end

      attributes = ActiveJob::Arguments.deserialize(hash.fetch("attributes")).first
      event_class.new(**attributes)
    end

    def klass
      Event
    end
  end
end
