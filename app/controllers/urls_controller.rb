class UrlsController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_role(:admin) }, only: [:new]
    def new
      @url = Url.new
    end
  
    def create
      @url = Url.new(url_params)
  
      if @url.save
        redirect_to @url , notice: 'URL successfully Created.'
      else
        render :new
      end
    end
  
    private
  
    def url_params
      params.require(:url).permit(:name, :url)
    end
  end
  