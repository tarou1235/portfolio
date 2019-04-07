class UsersController < ApplicationController
  def update
    @user=User.find(params[:id])
  end

  def index
    
  end
end
