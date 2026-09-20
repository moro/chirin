class OrderItem < ActiveRecord::Base
  belongs_to :order
  validates :sku, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
end
