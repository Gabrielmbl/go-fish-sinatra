require_relative 'card'
require_relative 'books'

class Player
  attr_accessor :api_key, :hand, :books
  attr_reader :name

  def initialize(name, hand: [], books: [])
    @name = name
    @api_key = ''
    @hand = hand
    @books = books
  end

  def to_h
    {
      name: @name,
      api_key: @api_key,
      hand: @hand.map(&:to_h),
      books: @books.map(&:to_h)
    }
  end
end
