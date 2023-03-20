# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_03_18_175240) do
  create_table "locations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "more_like_this", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "restaurant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "related_content_id"
    t.string "restaurant_name"
    t.index ["restaurant_id"], name: "index_more_like_this_on_restaurant_id"
  end

  create_table "restaurant_images", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "restaurant_id"
    t.string "image"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["restaurant_id"], name: "index_restaurant_images_on_restaurant_id"
  end

  create_table "restaurants", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "phone"
    t.string "price_range"
    t.string "rating"
    t.string "cuisines"
    t.string "cover_img"
    t.string "logo_img"
    t.string "save_percentage"
    t.string "address"
    t.bigint "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_restaurants_on_location_id"
  end

  add_foreign_key "more_like_this", "restaurants"
  add_foreign_key "restaurant_images", "restaurants"
  add_foreign_key "restaurants", "locations"
end
