class OrdersController < ActionController::Base
  def create
    input = params.require(:order).permit(:customer_id, items: [:sku, :quantity])
    order = OrderForm.new(
      customer: Customer.find(input.fetch(:customer_id)),
      items: input.fetch(:items).map(&:to_h)
    ).save!
    render json: { id: order.id }, status: :created
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end
end
