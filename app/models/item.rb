class Item < ApplicationRecord
    belongs_to :restaurant
    belongs_to :category
    has_and_belongs_to_many :restaurants
end
