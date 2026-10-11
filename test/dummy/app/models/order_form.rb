class OrderForm
  attr_reader :customer, :items

  def initialize(customer:, items:)
    @customer = customer
    @items = items
  end

  def save!
    Order.transaction do |transaction|
      receipt_email = customer.email
      order = Order.create!(customer:, receipt_email:)
      items.each { order.order_items.create!(it) }

      # Also waits for an enclosing transaction. This is not durable delivery.
      transaction.after_commit do
        Rails.event.notify(Events::OrderPlaced.new(order: order))
      end
      order
    end
  end
end
