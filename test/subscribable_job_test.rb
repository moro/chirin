require "minitest/autorun"
require "chirin"

class SubscribableJobTest < Minitest::Test
  class ReceiptJob < ActiveJob::Base
    include Chirin::SubscribableJob
    self.queue_adapter = :test

    class << self
      attr_accessor :received
    end

    def perform(payload)
      self.class.received = payload
    end
  end

  OrderPlaced = Struct.new(:order_id, keyword_init: true)

  class OrderPlacedSerializer < ActiveJob::Serializers::ObjectSerializer
    def serialize(event)
      super("order_id" => event.order_id)
    end

    def deserialize(hash)
      OrderPlaced.new(order_id: hash.fetch("order_id"))
    end

    def klass
      OrderPlaced
    end
  end

  ActiveJob::Serializers.add_serializers(OrderPlacedSerializer)

  def setup
    @reporter = ActiveSupport::EventReporter.new
    @reporter.raise_on_error = true
    ReceiptJob.queue_adapter.enqueued_jobs.clear
    ReceiptJob.received = nil
  end

  def test_matching_name_enqueues_payload_and_job_can_execute
    ReceiptJob.subscribe("order.placed", reporter: @reporter)
    @reporter.notify("order.imported", order_id: 1)
    assert_empty ReceiptJob.queue_adapter.enqueued_jobs

    @reporter.notify("order.placed", order_id: 42)
    assert_equal 1, ReceiptJob.queue_adapter.enqueued_jobs.size
    ActiveJob::Base.execute(ReceiptJob.queue_adapter.enqueued_jobs.first)
    assert_equal({ order_id: 42 }, ReceiptJob.received)
  end

  def test_custom_event_round_trips_with_explicit_serializer
    ReceiptJob.subscribe(OrderPlaced, reporter: @reporter)
    @reporter.notify("order.placed", order_id: 1)
    assert_empty ReceiptJob.queue_adapter.enqueued_jobs

    @reporter.notify(OrderPlaced.new(order_id: 42))
    ActiveJob::Base.execute(ReceiptJob.queue_adapter.enqueued_jobs.fetch(0))
    assert_instance_of OrderPlaced, ReceiptJob.received
    assert_equal 42, ReceiptJob.received.order_id
  end

  def test_returned_subscriber_can_be_removed
    subscriber = ReceiptJob.subscribe(:"order.placed", reporter: @reporter)
    @reporter.unsubscribe(subscriber)
    @reporter.notify("order.placed", order_id: 42)
    assert_empty ReceiptJob.queue_adapter.enqueued_jobs
  end

  def test_invalid_event_type_is_rejected
    assert_raises(ArgumentError) do
      ReceiptJob.subscribe(nil, reporter: @reporter)
    end
    assert_raises(ArgumentError) do
      ReceiptJob.subscribe(Class.new, reporter: @reporter)
    end
  end

  def test_class_filter_only_needs_the_name
    reporter = Object.new
    def reporter.subscribe(subscriber, &filter)
      @filter = filter
    end
    def reporter.matches?(name)
      @filter.call({ name: name }.freeze)
    end

    ReceiptJob.subscribe(OrderPlaced, reporter: reporter)
    assert reporter.matches?(OrderPlaced.name)
    refute reporter.matches?("order.placed")
    refute reporter.matches?("OtherOrderPlaced")
  end
end
