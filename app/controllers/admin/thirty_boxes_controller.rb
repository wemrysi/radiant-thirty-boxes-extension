require 'ThirtyBoxes'

class Admin::ThirtyBoxesController < ApplicationController
  def show
    @boxes_config = ThirtyBoxesConfig.attributes

    @auth_url = if !@boxes_config[:api_key].blank? &&
                   !@boxes_config[:app_name].blank?

      ThirtyBoxes.new(
        @boxes_config[:api_key],
        @boxes_config[:app_name]
      ).authorization_Url(update_token_thirty_boxes_url)
    else
      nil
    end
  end

  def update
    ThirtyBoxesConfig.attributes = params[:boxes]
    flash[:notice] = 'Configuration saved.'
    redirect_to(thirty_boxes_path)
  end

  def update_token
    if params[:token]
      ThirtyBoxesConfig.auth_token = params[:token]
      flash[:notice] = 'Authorization token saved.'
    end
    redirect_to(thirty_boxes_path)
  end
end
