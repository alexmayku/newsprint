class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.references :newsletter, null: false, foreign_key: true
      t.string :title, null: false
      t.string :author
      t.text :body_html, null: false
      t.integer :position, null: false, default: 0
      t.text :image_urls, array: true, default: []
      t.text :link_urls, array: true, default: []

      t.timestamps
    end
  end
end
