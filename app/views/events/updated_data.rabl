collection @days
attributes :event_count, :random_value

node(:date) { |day| day.date.to_time.to_i }
