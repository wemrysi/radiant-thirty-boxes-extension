class Admin::ThirtyBoxesController < ApplicationController
  def show
    @boxes_config = ThirtyBoxesConfig.attributes
  end

  def update
    ThirtyBoxesConfig.attributes = params[:boxes]
    flash[:notice] = 'Configuration saved.'
    redirect_to(thirty_boxes_path)
  end
end
