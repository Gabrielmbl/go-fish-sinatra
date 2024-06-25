class Card
  attr_accessor :rank, :suit

  def initialize(rank, suit)
    @rank = rank
    @suit = suit
  end

  def as_json
    {
      rank: rank,
      suit: suit
    }
  end
end
