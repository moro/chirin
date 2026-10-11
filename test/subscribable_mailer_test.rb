require_relative "rails_test_helper"

class SubscribableMailerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  self.use_transactional_tests = false

  setup do
    @reporter = ActiveSupport::EventReporter.new(raise_on_error: true)
    clear_enqueued_jobs
    clear_performed_jobs
    ActionMailer::Base.deliveries.clear
    @customer = Customer.create!(email: "original@example.com")
    @order = Order.create!(customer: @customer, receipt_email: @customer.email)
  end

  teardown do
    @order.destroy!
    @customer.destroy!
  end

  test "custom event is serialized and delivered later to the order snapshot" do
    OrderMailer.subscribe(:placed_event, Events::OrderPlaced, reporter: @reporter)
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      @reporter.notify(Events::OrderPlaced.new(order: @order))
    end
    assert_empty ActionMailer::Base.deliveries
    @customer.update!(email: "changed@example.com")
    perform_enqueued_jobs
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal ["original@example.com"], ActionMailer::Base.deliveries.last.to
    assert_includes ActionMailer::Base.deliveries.last.body.decoded, "注文番号: #{@order.id}"
  end

  test "name subscriptions ignore other events and can be removed" do
    subscriber = OrderMailer.subscribe(:placed_payload, :"order.placed", reporter: @reporter)
    assert_no_enqueued_jobs { @reporter.notify("order.imported", order_id: @order.id) }
    assert_enqueued_jobs 1 do
      @reporter.notify("order.placed", order_id: @order.id)
    end
    perform_enqueued_jobs
    assert_equal ["original@example.com"], ActionMailer::Base.deliveries.last.to
    @reporter.unsubscribe(subscriber)
    assert_no_enqueued_jobs { @reporter.notify("order.placed", order_id: @order.id) }
  end

  test "class subscription filter only needs the event name" do
    OrderMailer.subscribe(:placed_event, Events::OrderPlaced, reporter: @reporter)
    filter = @reporter.subscribers.fetch(0).fetch(:filter)
    assert filter.call({ name: Events::OrderPlaced.name }.freeze)
    refute filter.call({ name: "order.placed" }.freeze)
  end

  test "invalid actions and event types are rejected before registration" do
    assert_raises(ArgumentError) { OrderMailer.subscribe(:missing, "order.placed", reporter: @reporter) }
    assert_raises(ArgumentError) { OrderMailer.subscribe(:placed, nil, reporter: @reporter) }
    assert_raises(ArgumentError) { OrderMailer.subscribe(:placed, Class.new, reporter: @reporter) }
    assert_empty @reporter.subscribers
  end
end
