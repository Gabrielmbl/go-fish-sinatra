require 'rack/test'
require 'rspec'
require 'capybara'
require 'capybara/dsl'
ENV['RACK_ENV'] = 'test'
require_relative '../../lib/server'
require_relative '../../lib/card'
require_relative '../../lib/book'

RSpec.describe Server do
  include Rack::Test::Methods

  def app
    Server.new
  end

  after do
    Server.reset!
  end

  # it 'returns game status via API' do
  #   api_post

  #   api_key = JSON.parse(last_response.body)['api_key']
  #   expect(api_key).not_to be_nil

  #   api_get(api_key)

  #   expect(JSON.parse(last_response.body).keys).to include 'game'
  # end

  it 'returns 401 unauthorized for invalid API key' do
    api_post

    api_key = JSON.parse(last_response.body)['api_key']
    expect(api_key).not_to be_nil

    invalid_api_key = 'invalid_key'

    api_get(invalid_api_key)

    expect(last_response.status).to eq(401)
  end

  describe 'GET /game' do
    it 'returns Game' do
      api_post
      api_post

      api_key = JSON.parse(last_response.body)['api_key']
      expect(api_key).not_to be_nil

      api_get(api_key)

      expect(last_response.status).to eq 200
      expect(last_response).to match_json_schema('game')
    end
  end

  # describe 'POST /game' do

  # end

  def api_get(api_key)
    get '/game', nil, {
      'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64(api_key + ':X')}",
      'HTTP_ACCEPT' => 'application/json'
    }
  end

  def api_post
    post '/join', { 'name' => 'Gabriel' }.to_json, {
      'HTTP_ACCEPT' => 'application/json',
      'CONTENT_TYPE' => 'application/json'
    }
  end
end

RSpec.describe Server do
  include Capybara::DSL

  before do
    Capybara.app = Server.new
  end

  after do
    Server.reset!
  end

  it 'is possible to join a game' do
    visit '/'
    fill_in :name, with: 'John'
    click_on 'Join'
    expect(page).to have_content('Players')
    expect(page).to have_content('John')
  end

  it 'allows multiple players to join game' do
    session1, session2 = create_sessions_and_players
    expect(session2).to have_content('Player 1')
    session1.driver.refresh
    expect(session1).to have_content('Player 2')
  end

  it 'bolds only the current player and shows their API key' do
    session1, session2 = create_sessions_and_players
    expect(session2).to have_content('Player 1')
    expect(session1).to have_css('strong', count: 1)
    expect(session2).to have_css('strong', count: 1)
    expect(session1).to have_content('API Key', count: 1)
  end

  it 'should not allow empty player name' do
    visit '/'
    click_on 'Join'
    expect(page).to have_current_path('/')
  end

  it "should display only the player's hand" do
    session1, session2 = create_sessions_and_players
    refresh_sessions([session1, session2])
    expect(session1).to have_content('Your Hand:', count: 1)
    expect(session2).to have_content('Your Hand:', count: 1)
  end

  it "should display only the current player's hand" do
    session1, session2 = create_sessions_and_players
    game = Server.game
    game.players.first.hand = [Card.new('2', 'Clubs'), Card.new('3', 'Clubs')]
    game.players.last.hand = [Card.new('4', 'Clubs'), Card.new('5', 'Clubs')]
    refresh_sessions([session1, session2])
    session_has_content(session1, ['2 of Clubs', '3 of Clubs'])
    session_has_content(session2, ['4 of Clubs', '5 of Clubs'])
    session_does_not_have_content(session1, ['4 of Clubs', '5 of Clubs'])
  end

  it "should display everyone's books" do
    session1, session2 = create_sessions_and_players
    game = Server.game
    game.players.first.books = [Book.new([Card.new('2', 'Clubs'),
                                          Card.new('2', 'Diamonds'), Card.new('2', 'Hearts'), Card.new('2', 'Spades')])]
    game.players.last.books = [Book.new([Card.new('4', 'Clubs'),
                                         Card.new('4', 'Diamonds'), Card.new('4', 'Hearts'), Card.new('4', 'Spades')])]
    refresh_sessions([session1, session2])
    session_has_content(session1,
                        ['2 of Clubs', '2 of Diamonds', '2 of Hearts', '2 of Spades', '4 of Clubs', '4 of Diamonds', '4 of Hearts',
                         '4 of Spades'])
    session_has_content(session2,
                        ['2 of Clubs', '2 of Diamonds', '2 of Hearts', '2 of Spades', '4 of Clubs', '4 of Diamonds', '4 of Hearts',
                         '4 of Spades'])
  end

  it 'should display the turn actions to the current player' do
    session1, session2 = create_sessions_and_players
    game = Server.game
    refresh_sessions([session1, session2])
    session_has_content(session1, ["What's your move?"])
    session_does_not_have_content(session2, ["What's your move?"])
    Server.game.update_current_player
    refresh_sessions([session1, session2])
    session_does_not_have_content(session1, ["What's your move?"])
  end

  it 'should show other players as options for asking for a rank' do
    session1, session2 = create_sessions_and_players
    game = Server.game
    refresh_sessions([session1, session2])
    expect(session1).to have_select('player_to_ask', with_options: ['Player 2'])
    expect(session1).not_to have_select('player_to_ask', with_options: ['Player 1'])
  end

  it 'should show ranks in the current player hand as options for asking for a rank' do
    session1, session2 = create_sessions_and_players
    game = Server.game
    game.players.first.hand = [Card.new('2', 'Clubs'), Card.new('3', 'Clubs')]
    refresh_sessions([session1, session2])
    expect(session1).to have_select('card_rank', with_options: %w[2 3])
    expect(session1).not_to have_select('card_rank', with_options: %w[4 5])
  end

  describe 'POST /game' do
    before do
      @session1, @session2 = create_sessions_and_players
      @game = Server.game
      @game.players.first.hand = [Card.new('2', 'Clubs'), Card.new('3', 'Clubs')]
      @game.players.last.hand = [Card.new('3', 'Diamonds'), Card.new('5', 'Clubs')]
      refresh_sessions([@session1, @session2])
    end

    it 'should make a card to be added to one player and removed from the other' do
      ask_for_card(@session1, 'Player 2', '3')
      refresh_sessions([@session1, @session2])
      session_has_content(@session1, ['3 of Diamonds'])
      session_does_not_have_content(@session2, ['3 of Diamonds'])
    end

    it 'should make player fish if the rank is not in the opponent hand' do
      ask_for_card(@session1, 'Player 2', '4')
      refresh_sessions([@session1, @session2])
      session_has_content(@session1, ['A of Clubs'])
      session_does_not_have_content(@session2, ['A of Clubs'])
    end

    def ask_for_card(session, player, rank)
      session.select player, from: 'player_to_ask'
      session.select rank, from: 'card_rank'
      session.click_on 'Ask'
    end
  end

  # TODO: Can players play a turn
  # What are the cases to test around taking turns
  #   Validating that it is your turn -> Ensure

  def create_sessions_and_players
    session1 = Capybara::Session.new(:rack_test, Server.new)
    session2 = Capybara::Session.new(:rack_test, Server.new)
    [session1, session2].each_with_index do |session, index|
      player_name = "Player #{index + 1}"
      session.visit '/'
      session.fill_in :name, with: player_name
      session.click_on 'Join'
      expect(session).to have_content('Players')
    end
    [session1, session2]
  end

  def refresh_sessions(sessions)
    sessions.each { |session| session.driver.refresh }
  end

  def session_has_content(session, content)
    content.each do |c|
      expect(session).to have_content(c)
    end
  end

  def session_does_not_have_content(session, content)
    content.each do |c|
      expect(session).not_to have_content(c)
    end
  end
end
