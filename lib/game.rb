require_relative 'player'
require_relative 'card'
require_relative 'book'
require_relative 'Deck'

class Game
  attr_accessor :players, :turn_index, :deck, :started

  MIN_PLAYERS = 2
  STARTING_CARD_COUNT = 5

  def initialize
    @players = []
    @turn_index = 0
    @deck = Deck.new
    @started = false
  end

  def add_player(player)
    players << player
  end

  def empty?
    players.empty?
  end

  def start
    self.started = true
    deck.shuffle
    deal_to_players
  end

  def deal_to_players
    players.each do |player|
      STARTING_CARD_COUNT.times { player.add_to_hand([deck.deal]) }
    end
  end

  def as_json
    {
      turn_index: @turn_index,
      players: players.map(&:as_json),
      deck: deck.as_json
    }
  end
end
