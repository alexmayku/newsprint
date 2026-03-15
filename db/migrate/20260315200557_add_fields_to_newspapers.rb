class AddFieldsToNewspapers < ActiveRecord::Migration[8.1]
  def change
    add_reference :newspapers, :user, null: false, foreign_key: true
    add_column :newspapers, :title, :string, null: false, default: ""
    add_column :newspapers, :status, :integer, null: false, default: 0
    add_column :newspapers, :page_count, :integer
    add_column :newspapers, :edition_number, :integer, null: false, default: 0
    add_column :newspapers, :generated_at, :datetime
  end
end
