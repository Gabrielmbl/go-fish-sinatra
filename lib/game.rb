require_relative 'player'
require_relative 'card'
require_relative 'book'
require_relative 'Deck'

class Game
  attr_accessor :players, :current_player, :deck, :started

  MIN_PLAYERS = 2
  STARTING_CARD_COUNT = 5

  def initialize(players = [])
    @players = players
    @deck = Deck.new
    @started = false
    @current_player = players.first
  end

  def add_player(player)
    players << player
  end

  def empty?
    players.empty?
  end

  def start
    self.current_player = players.first
    self.started = true
    deck.shuffle
    deal_to_players
  end

  def deal_to_players
    players.each do |player|
      STARTING_CARD_COUNT.times { player.add_to_hand([deck.deal]) }
    end
  end

  def update_current_player(current_player = self.current_player)
    current_player_index = players.index(current_player)
    next_player_index = (current_player_index + 1) % players.length
    self.current_player = players[next_player_index]
  end

  def play_round(opponent, rank)
    cards = opponent.hand.select { |card| card.rank == rank }
    current_player.add_to_hand(cards)
    opponent.remove_by_rank(rank)
  end

  def as_json
    {
      current_player: current_player.as_json,
      players: players.map(&:as_json),
      deck: deck.as_json
    }
  end
end
