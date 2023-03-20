class Restaurant < ApplicationRecord
    belongs_to :location
    has_many :more_like_this
    has_many :restaurant_images
end
