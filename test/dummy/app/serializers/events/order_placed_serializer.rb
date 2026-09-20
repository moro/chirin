module Events
  class OrderPlacedSerializer < ActiveJob::Serializers::ObjectSerializer
    def serialize(event)
      super("order" => ActiveJob::Arguments.serialize([event.order]))
    end

    def deserialize(hash)
      OrderPlaced.new(order: ActiveJob::Arguments.deserialize(hash.fetch("order")).first)
    end

    def klass
      OrderPlaced
    end
  end
end
