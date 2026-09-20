class OrderForm
  def initialize(customer:, items:)
    @customer = customer
    @items = items
  end

  def save!
    Order.transaction do |transaction|
      order = Order.create!(customer: @customer, receipt_email: @customer.email)
      @items.each { |item| order.order_items.create!(item) }

      # Also waits for an enclosing transaction. This is not durable delivery.
      transaction.after_commit do
        Rails.event.notify(Events::OrderPlaced.new(order: order))
      end
      order
    end
  end
end
