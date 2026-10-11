class OrderMailer < ActionMailer::Base
  include Chirin::SubscribableMailer
  default from: "orders@example.com"

  def placed(order)
    mail(to: order.receipt_email, subject: "ご注文を受け付けました") do |format|
      format.text { render plain: "注文番号: #{order.id}\n明細数: #{order.order_items.count}" }
    end
  end

  def placed_event(event)
    placed(event.order)
  end

  def placed_payload(payload)
    placed(Order.find(payload.fetch(:order_id)))
  end
end
