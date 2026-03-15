class CreateJoinTableNewspapersNewsletters < ActiveRecord::Migration[8.1]
  def change
    create_join_table :newspapers, :newsletters do |t|
      t.index [:newspaper_id, :newsletter_id], unique: true
      t.index [:newsletter_id, :newspaper_id]
    end
  end
end
