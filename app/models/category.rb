class Category < ApplicationRecord
    belongs_to :restaurant
    has_many :items
end
