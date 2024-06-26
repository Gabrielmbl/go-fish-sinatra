# spec/deck_spec.rb

require_relative '../lib/deck'

RSpec.describe Deck do
  let(:deck) { Deck.new }

  describe '#initialize' do
    it 'responds to cards' do
      expect(deck).to respond_to(:cards)
    end

    it 'should have 52 cards when created' do
      expect(deck.num_cards).to eq(52)
    end
  end

  describe '#deal' do
    it 'should remove a card from the deck' do
      num_cards = deck.num_cards
      card = deck.deal
      expect(card).not_to be_nil
      expect(deck.current_num_cards).to eq(num_cards - 1)
    end

    it 'should deal unique cards' do
      card1 = deck.deal
      card2 = deck.deal
      expect(card1).not_to eq(card2)
    end
  end

  describe '#shuffle' do
    it 'should shuffle the deck' do
      original_cards = deck.cards.dup
      deck.shuffle
      expect(deck.cards).not_to eq(original_cards)
    end
  end
end
