class Event
  include Mongoid::Document
  include Mongoid::Timestamps

  field :api_id,     type: Numeric
  field :title
  field :description
  field :date_start, type: DateTime
  field :date_end,   type: DateTime
  field :updated_at, type: DateTime

  index(api_id: 1)
  index(date_start: 1, date_end: 1)
end
