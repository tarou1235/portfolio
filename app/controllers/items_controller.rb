class ItemsController < ApplicationController

  def index

  end

  def update
    @item=Item.find(params[:id])
    if @item.update_attributes(item_params)
       cost=@item.cost
       flash[:success] = "更新しました"
       redirect_to "/costs/#{cost.id}/edit"
    else

    end
  end

  private
  def item_params
    params.require(:item).permit(:name, :payment)
  end

end
