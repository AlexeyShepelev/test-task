class EventsController < ApplicationController
  def index
    @current_date =
        if params[:year] && params[:month]
          Time.new(params[:year], params[:month])
        else
          Time.new
        end

    @days = Day.where(:date.gte => @current_date.beginning_of_month,
                      :date.lte => @current_date.end_of_month).all.entries

    respond_to do |format|
      format.html
      format.js { render layout: false }
    end
  end

  def updated_data
    EventCollector.update_calendar(params[:year], params[:month])

    current_date = Time.new(params[:year], params[:month])
    @days = Day.where(:date.gte => current_date.beginning_of_month,
                      :date.lte => current_date.end_of_month).all.entries

    render layout: false
  end
end
