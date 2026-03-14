class CreateNewspapers < ActiveRecord::Migration[8.1]
  def change
    create_table :newspapers do |t|
      t.timestamps
    end
  end
end
