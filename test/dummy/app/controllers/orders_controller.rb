class OrdersController < ActionController::Base
  def create
    input = params.expect(order: [items: [[:sku, :quantity]]])
    items = input.fetch(:items).map(&:to_h)

    order = OrderForm.new(
      customer: current_customer,
      items:
    ).save!

    render json: { id: order.id }, status: :created
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end

  private
    # Test-only customer selection, not authentication.
    def current_customer
      Customer.find(request.headers.fetch("X-Customer-Id"))
    end
end
