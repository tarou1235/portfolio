class ItemsController < ApplicationController

  def index

  end

  def update
    @item=Item.find(params[:id])
    if @item.update_attributes(item_params)
       redirect_to items_url
    else

    end
  end

  private
  def item_params
    params.require(:item).permit(:name, :payment)
  end

end
