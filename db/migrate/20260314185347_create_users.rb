class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.text :google_token_enc
      t.string :stripe_customer_id
      t.jsonb :delivery_address

      t.timestamps
    end

    add_index :users, "LOWER(email)", unique: true
  end
end
