class CreateNewsletters < ActiveRecord::Migration[8.1]
  def change
    create_table :newsletters do |t|
      t.references :user, null: false, foreign_key: true
      t.string :sender_email, null: false
      t.string :title, null: false
      t.string :logo_url
      t.integer :est_pages, null: false
      t.datetime :latest_issue_date, null: false

      t.timestamps
    end

    add_index :newsletters, [ :user_id, :sender_email ], unique: true
  end
end
