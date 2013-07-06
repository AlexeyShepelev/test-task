class EventsController < ApplicationController
  def index
    @current_date =
        if params[:year] && params[:month]
          Time.new(params[:year], params[:month])
        else
          Time.new
        end

    respond_to do |format|
      format.html
      format.js { render layout: false }
    end
  end
end
