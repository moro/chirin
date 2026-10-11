require_relative "rails_test_helper"

class OrderFlowTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  # Real commits matter to this test; use explicit cleanup instead of fixtures.
  self.use_transactional_tests = false

  setup do
    OrderItem.delete_all
    Order.delete_all
    Customer.delete_all
    clear_enqueued_jobs
    clear_performed_jobs
    ActionMailer::Base.deliveries.clear
    @customer = Customer.create!(email: "at-order@example.com")
  end

  test "request saves order and items, then serialized event sends receipt to snapshot" do
    assert_enqueued_jobs 1, only: OrderReceiptJob do
      post "/orders", params: {
        order: { customer_id: -1, items: [{ sku: "BOOK", quantity: 2 }] }
      }, headers: { "X-Customer-Id" => @customer.id.to_s }, as: :json
    end
    assert_response :created
    order = Order.find(response.parsed_body.fetch("id"))
    assert_equal @customer.id, order.customer_id
    assert_equal "at-order@example.com", order.receipt_email
    assert_equal [["BOOK", 2]], order.order_items.pluck(:sku, :quantity)
    assert_empty ActionMailer::Base.deliveries

    argument = enqueued_jobs.fetch(0).fetch("arguments").fetch(0)
    assert_equal "Chirin::EventSerializer", argument.fetch("_aj_serialized")
    assert_equal "Events::OrderPlaced", argument.fetch("event_class")
    assert_equal order.to_global_id.to_s, argument.fetch("attributes").fetch(0).fetch("order").fetch("_aj_globalid")
    @customer.update!(email: "latest@example.com")
    perform_enqueued_jobs

    assert_equal 1, ActionMailer::Base.deliveries.size
    message = ActionMailer::Base.deliveries.last
    assert_equal ["at-order@example.com"], message.to
    assert_equal "ご注文を受け付けました", message.subject
    assert_includes message.body.decoded, "注文番号: #{order.id}"
  end

  test "invalid item rolls back order and all items without notifying" do
    assert_no_enqueued_jobs do
      post "/orders", params: {
        order: { items: [
          { sku: "BOOK", quantity: 1 }, { sku: "BROKEN", quantity: 0 }
        ] }
      }, headers: { "X-Customer-Id" => @customer.id.to_s }, as: :json
    end
    assert_response :unprocessable_entity
    assert_equal 0, Order.count
    assert_equal 0, OrderItem.count
    assert_empty ActionMailer::Base.deliveries
  end

  test "enclosing transaction rollback does not enqueue receipt" do
    assert_no_enqueued_jobs do
      Order.transaction do
        OrderForm.new(customer: @customer, items: [{ sku: "BOOK", quantity: 1 }]).save!
        assert_empty enqueued_jobs
        raise ActiveRecord::Rollback
      end
    end
    assert_equal 0, Order.count
    assert_equal 0, OrderItem.count
  end

  test "importing an order does not imply a new order placement" do
    assert_no_enqueued_jobs do
      Order.transaction do
        order = Order.create!(customer: @customer, receipt_email: "historical@example.com")
        order.order_items.create!(sku: "OLD", quantity: 1)
      end
    end
    perform_enqueued_jobs
    assert_equal 1, Order.count
    assert_empty ActionMailer::Base.deliveries
  end
end
