module Chirin
  module EventFilter
    def self.for(event_type)
      name = case event_type
      when Class
        event_type.name or raise ArgumentError, "event_type must be a named Class"
      when String, Symbol
        event_type.to_s
      else
        raise ArgumentError, "event_type must be a Class, String, or Symbol"
      end

      ->(event) { event[:name] == name }
    end
  end
end
