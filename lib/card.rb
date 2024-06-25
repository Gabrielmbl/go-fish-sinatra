class Card
  attr_accessor :rank, :suit

  def initialize(rank, suit)
    @rank = rank
    @suit = suit
  end

  def to_h
    {
      rank: rank,
      suit: suit
    }
  end
end
