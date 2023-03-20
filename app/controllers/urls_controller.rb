class UrlsController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_role(:admin) }, only: [:new]
    def new
      @url = Url.new
    end
  
    def create
      @url = Url.new(url_params)
  
      if @url.save
        if system("bundle exec rake scrape:restaurants")
          puts "Task executed successfully"
        else
          puts "Task failed"
        end
        redirect_to @url , notice: 'Task for this url has been executed successfully! Refresh the Home page now!'
      else
        render :new
      end
    end
  
    private
  
    def url_params
      params.require(:url).permit(:name, :url)
    end
  end
  