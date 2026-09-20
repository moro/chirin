ActiveRecord::Schema.define do
  create_table :customers, force: true do |table|
    table.string :email, null: false
  end

  create_table :orders, force: true do |table|
    table.references :customer, null: false, foreign_key: true
    table.string :receipt_email, null: false
  end

  create_table :order_items, force: true do |table|
    table.references :order, null: false, foreign_key: true
    table.string :sku, null: false
    table.integer :quantity, null: false
  end
end
