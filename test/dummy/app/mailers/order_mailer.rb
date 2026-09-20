class OrderMailer < ActionMailer::Base
  default from: "orders@example.com"

  def placed(order)
    mail(to: order.receipt_email, subject: "ご注文を受け付けました") do |format|
      format.text { render plain: "注文番号: #{order.id}\n明細数: #{order.order_items.count}" }
    end
  end
end
