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

  def show_by_range
    begin_day = Time.at(params[:date_start].to_i).beginning_of_day
    end_day = Time.at(params[:date_end].to_i).end_of_day

    @events = Event.any_of({date_start: {gte: begin_day, lte: end_day}},
                           {date_end: {gte: begin_day, lte: end_day}},
                           {:date_start.lte => begin_day, :date_end.gte => end_day},
                           {:date_start.gte => begin_day, :date_end.lte => end_day})
                   .order_by(:date_start.asc).all.page(params[:page]).per(4)

    render layout: false
  end
end
