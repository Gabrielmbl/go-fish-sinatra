require_relative '../../lib/game'

RSpec.describe Game do
  let(:player1) { Player.new('Player 1') }
  let(:player2) { Player.new('Player 2') }
  let(:game) { Game.new([player1, player2]) }
  let(:card1) { Card.new('2', 'Hearts') }
  let(:card2) { Card.new('2', 'Diamonds') }
  let(:card3) { Card.new('2', 'Clubs') }

  describe '#play_round' do
    it 'should take a card from one player and give it to another' do
      player1.hand = [card1, card2]
      player2.hand = [card3]
      game.play_round(player2, '2')
      expect(player1.hand).to match_array([card1, card2, card3])
      expect(player2.hand).to be_empty
    end
  end
end
