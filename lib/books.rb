require_relative 'card'

class Book
  attr_accessor :cards_array

  def initialize(cards_array = [])
    @cards_array = cards_array
  end

  def value
    sum = 0
    cards_array.each do |cards|
      sum += cards.first.numerical_rank
    end
    sum
  end

  def count
    cards_array.count
  end

  def as_json
    {
      cards_array: cards_array.map { |cards| cards.map(&:as_json) },
      value: value,
      count: count
    }
  end
end
