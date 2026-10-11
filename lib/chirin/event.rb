module Chirin
  # Opt a Data class into Chirin's shared Active Job serializer.
  module Event
    def self.included(base)
      unless base < Data
        raise ArgumentError, "Chirin::Event must be included in a Data class"
      end
    end
  end
end
