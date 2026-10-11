require "minitest/autorun"
require "json"
require "chirin"

class EventSerializerTest < Minitest::Test
  Placed = Data.define(:order_id, :at, :metadata) do
    include Chirin::Event
  end
  Imported = Data.define(:events) do
    include Chirin::Event
  end
  Unmarked = Data.define(:order_id)

  def round_trip(event)
    arguments = ActiveJob::Arguments.serialize([event])
    ActiveJob::Arguments.deserialize(JSON.parse(JSON.generate(arguments))).first
  end

  def test_multiple_event_classes_and_nested_values_round_trip
    at = Time.utc(2026, 10, 11, 12, 34, 56)
    event = Placed.new(order_id: 42, at: at, metadata: { source: :web, flags: [true, false, nil] })
    restored = round_trip(event)
    assert_instance_of Placed, restored
    assert_equal event, restored
    assert restored.frozen?

    batch = Imported.new(events: [event])
    assert_equal batch, round_trip(batch)
    assert_instance_of Placed, round_trip(batch).events.first
  end

  def test_unmarked_data_is_not_claimed
    event = Unmarked.new(order_id: 42)
    refute Chirin::EventSerializer.serialize?(event)
    assert_raises(ActiveJob::SerializationError) { round_trip(event) }
  end

  def test_anonymous_event_class_is_rejected
    event_class = Data.define(:id) { include Chirin::Event }
    assert_raises(ActiveJob::SerializationError) { round_trip(event_class.new(id: 1)) }
  end

  def test_marker_requires_data
    assert_raises(ArgumentError) { Class.new { include Chirin::Event } }
  end

  def test_restore_rejects_classes_without_the_marker
    hash = Chirin::EventSerializer.serialize(Placed.new(order_id: 1, at: nil, metadata: {}))
    ["String", Unmarked.name, "Chirin::Event"].each do |class_name|
      assert_raises(ArgumentError) do
        Chirin::EventSerializer.deserialize(hash.merge("event_class" => class_name))
      end
    end
  end

  def test_unsupported_members_are_not_silently_converted
    event = Placed.new(order_id: 1, at: nil, metadata: Object.new)
    assert_raises(ActiveJob::SerializationError) { round_trip(event) }
  end
end
