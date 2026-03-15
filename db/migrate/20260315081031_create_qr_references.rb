class CreateQrReferences < ActiveRecord::Migration[8.1]
  def change
    create_table :qr_references do |t|
      t.references :article, null: false, foreign_key: true
      t.text :url, null: false
      t.integer :reference_number, null: false
      t.string :label, null: false
      t.text :qr_svg

      t.timestamps
    end
  end
end
