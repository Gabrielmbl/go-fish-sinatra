class Game
  attr_accessor :players, :turn_index, :deck

  def initialize
    @players = []
    @turn_index = 0
    @deck = []
  end

  def add_player(player)
    players << player
  end

  def empty?
    players.empty?
  end
end
