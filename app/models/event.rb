class Event
  include Mongoid::Document

  field :api_id,     type: Numeric
  field :title
  field :description
  field :date_start, type: Numeric
  field :date_end,   type: Numeric
  field :updated_at, type: Numeric

  index(api_id: 1)
  index(date_start: 1, date_end: 1)
end
