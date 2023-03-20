class CreateLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :locations do |t|
      t.string :name
      t.string :address, null: true
      t.string :city, null: true
      t.string :state, null: true
      t.string :zip, null: true

      t.timestamps
    end
  end
end
