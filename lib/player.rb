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

  def add_to_hand(cards)
    hand.unshift(*cards)
  end

  def remove_by_rank(rank)
    hand.delete_if { |card| card.rank == rank }
  end

  def hand_has_ranks?(rank)
    hand.any? { |card| card.rank == rank }
  end

  def hand_has_books?
    ranks = hand.map(&:rank)
    ranks.each do |rank|
      return true if ranks.count(rank) == 4
    end
    false
  end

  def add_to_books
    books_added = []
    rank_counts = hand.map(&:rank).group_by(&:itself).transform_values(&:count)
    rank_counts.each do |rank, count|
      next unless count == 4

      cards = hand.select { |card| card.rank == rank }
      books.cards_array << cards
      books_added << rank
      remove_by_rank(rank)
    end
    nil
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
