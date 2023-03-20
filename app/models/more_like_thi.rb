class MoreLikeThi < ApplicationRecord
    belongs_to :restaurant
    has_many :restaurant_images
end
