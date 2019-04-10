class CostsController < ApplicationController
  def index

  end

  def new
    @cost=Cost.new
  end

  def create
    user=User.find_by(params[:line_id])
    cost=Cost.create(name:cost_params[:name],payment:cost_params[:payment],user_id:user.id)
  end


  def edit
    @cost=Cost.find(params[:id])
    @items=@cost.items

  end

  def update
    @cost=Cost.find(params[:id])
    if @cost.update_attributes(cost_params)

    else

    end

  end

  private
  def cost_params
    params.require(:cost).permit(:name, :payment)
  end
end
