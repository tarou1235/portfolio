class UsersController < ApplicationController
  def update
    @user=User.find(params[:id])
  end
end
