#!/usr/bin/env ruby

require File.expand_path('../../../config/environment', __FILE__)

begin
  days = {}

  client = Savon.client(wsdl: 'http://events.scottish-enterprise.com/eventsservice/EventsWebService.svc?wsdl',
                        log_level: :error)

  response = client.call(:get_events)
  events = response.to_hash[:get_events_response][:get_events_result][:diffgram][:new_data_set][:table].map do |row|
    if !row[:date_start].blank? && row[:date_start].kind_of?(DateTime) &&
       !row[:date_end].blank? && row[:date_end].kind_of?(DateTime)

      (row[:date_start].to_date..row[:date_end].to_date).each do |day|
        days[day] = days.has_key?(day) ? days[day] + 1 : 1
      end
    end

    { api_id: row[:event_id], title: row[:title], description: row[:description],
      date_start: row[:date_start], date_end: row[:date_end], updated_at: row[:update_date] }
  end

  Event.create(events)
  days.each { |k, v| Day.create(date: k, event_count: v, random_value: rand(5..99)) }

rescue => error
  p error
end
