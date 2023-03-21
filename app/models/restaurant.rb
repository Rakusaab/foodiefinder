class Restaurant < ApplicationRecord
    belongs_to :location
    has_many :more_like_this
    has_many :restaurant_images
    has_many :categories
    has_many :items
    has_and_belongs_to_many :items
end
