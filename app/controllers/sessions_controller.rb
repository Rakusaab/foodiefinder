class Users::SessionsController < Devise::SessionsController
    # DELETE /users/sign_out
    def destroy
      super
    end
  end
  