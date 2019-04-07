class CostsController < ApplicationController
  def index

  end


  def edit
    cost=Cost.find(params[:id])
    @items=cost.items
  end

  def update
    @cost=Cost.find(params[:id])
    if @cost.update_attributes(cost_params)
       redirect_to cost_url
    else

    end

  end

  private
  def item_params
    params.require(:cost).permit(:name, :payment)
  end
end
