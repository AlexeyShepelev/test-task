class Day
  include Mongoid::Document

  field :date,         type: Date
  field :event_count,  type: Numeric, default: 0
  field :random_value, type: Numeric

  index(date: 1)

  validates :date, presence: true, uniqueness: true
  validates_numericality_of :event_count, greater_than_or_equal_to: 0
end
