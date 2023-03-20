class CreateMoreLikeThis < ActiveRecord::Migration[7.0]
  def change
    create_table :more_like_this do |t|
      t.references :restaurant, null: false, foreign_key: true
      t.string :restaurant_name, null: true
      t.integer :related_content_id, null: true
      t.timestamps
    end
  end
end
