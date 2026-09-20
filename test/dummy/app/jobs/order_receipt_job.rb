class OrderReceiptJob < ActiveJob::Base
  include Chirin::SubscribableJob

  def perform(event)
    OrderMailer.placed(event.order).deliver_now
  end
end
