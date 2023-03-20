class CreateUrls < ActiveRecord::Migration[7.0]
  def change
    create_table :urls do |t|
      t.string :name, null: true  
      t.string :url, null: true  
      t.timestamps
    end
  end
end
