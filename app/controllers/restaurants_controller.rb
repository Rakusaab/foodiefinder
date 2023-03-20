class RestaurantsController < ApplicationController
  def index
    @locations = Location.all.order(name: :asc)
    @restaurants = Restaurant.all.includes(:location).order(name: :asc)
    @location = []
     # Check if a location parameter is provided
     if params[:location].present?
      # return render json: Location.find_by(name: params[:location])
      @location = Location.find_by(name: params[:location])
      # return render json: @location
      @restaurants = @location.present? == true ? @location.restaurants : @restaurants = []
      # return render json: @restaurants
    end
    # Check if a search parameter is provided
    if params[:search].present?
      @restaurants = @restaurants.where("LOWER(name) LIKE ? ", "%#{params[:search].downcase}%")
    end
  end

  def show
    @restaurant = Restaurant.find(params[:id])
    @more_like_this = @restaurant.more_like_this.order(created_at: :desc)
    @restaurant_images = @restaurant.restaurant_images.order(created_at: :desc)
  end
end
