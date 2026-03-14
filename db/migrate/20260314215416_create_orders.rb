class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :newspaper, null: true, foreign_key: true
      t.integer :order_type, null: false, default: 0
      t.integer :frequency
      t.integer :status, null: false, default: 0
      t.integer :page_count, null: false
      t.string :pdf_url
      t.string :stripe_payment_id, null: false
      t.jsonb :delivery_address, null: false, default: {}
      t.bigint :newsletter_ids, array: true, null: false, default: []

      t.timestamps
    end
  end
end
