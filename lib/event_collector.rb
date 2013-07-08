require 'day'
require 'event'

module EventCollector
  class QueueItem < Struct.new(:uid, :year, :month, :status); end

  # Statuses
  NEW = 0
  DELAY = 1
  COMPLETE = 2

  class << self
    attr_accessor :queue, :last_check

    def mutex
      @mutex ||= Mutex.new
    end

    def queue
      @queue ||= []
    end

    def last_check
      @last_check ||= (Event.order_by(:updated_at.desc).first.updated_at).strftime('%Y-%m-%dT%H:%M:%S')
    end

    def run
      Thread.new do
        loop do
          begin
            # Change queue items status
            queue_items = self.mutex.synchronize do
              new_items = self.queue.select{ |q| q.status == NEW }
              new_items.each { |i| i.status = DELAY }
            end

            unless queue_items.empty?
              threads = []
              deleted_events = []
              updated_events = []
              days_old_event = {}
              days_deleted_events = {}
              days_updated_events = {}

              # Get deleted events
              threads << Thread.new do
                client = Savon.client(wsdl: 'http://events.scottish-enterprise.com/eventsservice/EventsWebService.svc?wsdl',
                                      env_namespace: :soapenv, namespace_identifier: :tem, log_level: :error)

                response = client.call(:get_all_deleted_events, message: { 'tem:dtLastUpdate' => self.last_check })
                if (response = response.to_hash[:get_all_deleted_events_response][:get_all_deleted_events_result][:diffgram][:new_data_set])
                  deleted_events = [response[:table]].flatten(1).map do |row|
                    if !row[:date_start].blank? && row[:date_start].kind_of?(DateTime) &&
                       !row[:date_end].blank? && row[:date_end].kind_of?(DateTime)

                      (row[:date_start].to_date..row[:date_end].to_date).each do |day|
                        days_deleted_events[day] = days_deleted_events.has_key?(day) ? days_deleted_events[day] + 1 : 1
                      end
                    end

                    { api_id: row[:event_id] }
                  end
                end
              end

              # Get updated events
              threads << Thread.new do
                client = Savon.client(wsdl: 'http://events.scottish-enterprise.com/eventsservice/EventsWebService.svc?wsdl',
                                      env_namespace: :soapenv, namespace_identifier: :tem, log_level: :error)

                response = client.call(:get_all_events_by_date, message: { 'tem:dtLastUpdate' => self.last_check })
                if (response = response.to_hash[:get_all_events_by_date_response][:get_all_events_by_date_result][:diffgram][:new_data_set])
                  updated_events = [response[:table]].flatten(1).map do |row|
                    if !row[:date_start].blank? && row[:date_start].kind_of?(DateTime) &&
                       !row[:date_end].blank? && row[:date_end].kind_of?(DateTime)

                      (row[:date_start].to_date..row[:date_end].to_date).each do |day|
                        days_updated_events[day] = days_updated_events.has_key?(day) ? days_updated_events[day] + 1 : 1
                      end
                    end

                    { api_id: row[:event_id], title: row[:title], description: row[:short_desc],
                      date_start: row[:date_start], date_end: row[:date_end], updated_at: row[:update_date] }
                  end
                end
              end

              threads.each(&:join)

              # Delete events
              unless deleted_events.empty?
                Event.in(api_id: deleted_events.map{ |e| e[:api_id] }).delete_all
              end

              # Update events
              unless updated_events.empty?
                updated_events.each do |e|
                  event = Event.where(api_id: e[:api_id]).first

                  if !event.date_start.blank? && event.date_start.kind_of?(DateTime) &&
                     !event.date_end.blank? && event.date_end.kind_of?(DateTime)

                    (event.date_start.to_date..event.date_end.to_date).each do |day|
                      days_old_event[day] = days_old_event.has_key?(day) ? days_old_event[day] + 1 : 1
                    end
                  end

                  event.update_attributes(e)
                end
              end

              # Change event_count in days
              days = days_updated_events

              days_deleted_events.merge(days_old_event) { |_, v1, v2| v1 + v2 }.each do |k, v|
                days[k] = days.has_key?(k) ? days[k] - v : -1
              end

              days.each do |k, v|
                if (day = Day.where(date: k.to_time).first)
                  day.update_attribute(:event_count, day.event_count + v)
                else
                  Day.create(date: k, event_count: v, random_value: rand(5..99))
                end
              end

              # Update day random values and change queue item status
              self.mutex.synchronize do
                updated_days =
                    queue_items.map do |item|
                      item.status = COMPLETE

                      request_date = Date.new(item.year.to_i, item.month.to_i)
                      (request_date.beginning_of_month.to_date..request_date.end_of_month.to_date).to_a
                    end.flatten.uniq

                Day.in(date: updated_days).each do |day|
                  day.update_attribute(:random_value, rand(5..99)) unless day.event_count.zero?
                end
              end

              self.last_check = DateTime.current.strftime('%Y-%m-%dT%H:%M:%S')
            end

          rescue => error
            puts error
            puts error.backtrace
          ensure
            sleep Settings.event_collector.timeout
          end
        end
      end
    end

    def update_calendar(year, month)
      request_uid = SecureRandom.uuid

      queue_item = QueueItem.new(request_uid, year, month, NEW)
      self.queue << queue_item

      Timeout::timeout(30) do
        begin
          queue_item = self.mutex.synchronize { self.queue.select{ |q| q.uid == request_uid }.first }
        end while queue_item && queue_item.status != COMPLETE && sleep(0.5)
      end

    rescue => error
      puts error
      puts error.backtrace
    end
  end
end
