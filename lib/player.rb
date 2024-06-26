require_relative 'card'
require_relative 'book'

class Player
  attr_accessor :api_key, :hand, :books
  attr_reader :name

  def initialize(name, hand: [], books: [])
    @name = name
    @api_key = ''
    @hand = hand
    @books = books
  end

  def as_json
    {
      name: @name,
      api_key: @api_key,
      hand: @hand.map(&:as_json),
      books: @books.map(&:as_json)
    }
  end
end
