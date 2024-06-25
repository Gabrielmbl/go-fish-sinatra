class Player
  attr_accessor :api_key, :hand, :books
  attr_reader :name

  def initialize(name, hand: [], books: [])
    @name = name
    @api_key = ''
    @hand = hand
    @books = books
  end
end
