class Event
  include Mongoid::Document

  field :title
  field :description
  field :date_start, type: Numeric
  field :date_end,   type: Numeric

  index(date_start: 1, date_end: 1)
end
