class UsersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_user, only: [:show, :edit, :update, :destroy]
  
    # Only allow admin users to access index and destroy actions
    before_action :require_admin, only: [:index, :destroy]
  
    def index
      @users = User.all
    end
  
    def show
    end
  
    def edit
    end
  
    def update
      if @user.update(user_params)
        redirect_to @user, notice: 'User was successfully updated.'
      else
        render :edit
      end
    end
  
    def destroy
      @user.destroy
      redirect_to users_url, notice: 'User was successfully destroyed.'
    end
  
    private
  
    def set_user
      @user = User.find(params[:id])
    end
  
    def user_params
      # Add :role to the permitted parameters if it's present
      if params[:user][:role].present?
        params.require(:user).permit(:email, :password, :password_confirmation, :role)
      else
        params.require(:user).permit(:email, :password, :password_confirmation)
      end
    end
  
    def require_admin
      unless current_user.admin?
        flash[:error] = "You must be an admin to access that page."
        redirect_to root_path
      end
    end
  end
  