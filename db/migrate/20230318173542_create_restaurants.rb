class CreateRestaurants < ActiveRecord::Migration[7.0]
  def change
    create_table :restaurants do |t|
      t.string :name
      t.string :web_name, null: true
      t.text :description, null: true
      t.string :phone, null: true
      t.string :price_range, null: true
      t.string :rating, null: true
      t.string :cuisines, null: true
      t.string :cover_img, null: true
      t.string :logo_img, null: true
      t.string :save_percentage, null: true
      t.string :address, null: true
      t.references :location, null: false, foreign_key: true

      t.timestamps
    end
  end
end
