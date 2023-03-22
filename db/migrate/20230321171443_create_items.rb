class CreateItems < ActiveRecord::Migration[7.0]
  def change
    create_table :items do |t|
      t.references :restaurant, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.string :image
      t.decimal :price
      t.string :food_type

      t.timestamps
    end
  end
end
