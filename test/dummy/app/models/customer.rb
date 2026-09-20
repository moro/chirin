class Customer < ActiveRecord::Base
  validates :email, presence: true
end
