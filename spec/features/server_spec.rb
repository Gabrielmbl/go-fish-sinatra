require 'rack/test'
require 'rspec'
require 'capybara'
require 'capybara/dsl'
ENV['RACK_ENV'] = 'test'
require_relative '../../lib/server'

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
      get '/game', format: :json

      api_post

      api_key = JSON.parse(last_response.body)['api_key']
      expect(api_key).not_to be_nil

      api_get(api_key)

      expect(last_response.status).to eq 200
      expect(last_response).to match_json_schema('game')
    end
  end

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
    session1 = Capybara::Session.new(:rack_test, Server.new)
    session2 = Capybara::Session.new(:rack_test, Server.new)
    [session1, session2].each_with_index do |session, index|
      player_name = "Player #{index + 1}"
      session.visit '/'
      session.fill_in :name, with: player_name
      session.click_on 'Join'
      expect(session).to have_content('Players')
      expect(session).to have_css('b', text: player_name)
    end
    expect(session2).to have_content('Player 1')
    session1.driver.refresh
    expect(session1).to have_content('Player 2')
  end

  it 'bolds only the current player and shows their API key' do
    session1 = Capybara::Session.new(:rack_test, Server.new)
    session2 = Capybara::Session.new(:rack_test, Server.new)
    [session1, session2].each_with_index do |session, index|
      player_name = "Player #{index + 1}"
      session.visit '/'
      session.fill_in :name, with: player_name
      session.click_on 'Join'
      expect(session).to have_content('Players')
    end
    expect(session2).to have_content('Player 1')
    expect(session1).to have_css('b', count: 1)
    expect(session2).to have_css('b', count: 1)
    expect(session1).to have_content('API Key', count: 1)
  end

  it 'should not allow empty player name' do
    visit '/'
    click_on 'Join'
    expect(page).to have_current_path('/')
  end

  it "should display only the player's hand" do
    session1, session2 = create_sessions_and_players
    expect(session1).to have_content('Your Hand', count: 1)
    expect(session2).to have_content('Your Hand', count: 1)
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
end
