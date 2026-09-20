class Order < ActiveRecord::Base
  belongs_to :customer
  has_many :order_items, dependent: :destroy
  validates :receipt_email, presence: true
end
