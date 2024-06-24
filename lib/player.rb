class Player
  attr_accessor :api_key
  attr_reader :name

  def initialize(name)
    @name = name
    @api_key = ""
  end
end