require 'sinatra'
require 'sinatra/json'
require 'sinatra/respond_with'
require 'rack/contrib'
require_relative 'game'
require_relative 'player'

class Server < Sinatra::Base
  enable :sessions
  register Sinatra::RespondWith
  use Rack::JSONBodyParser

  def self.api_keys
    @@api_keys ||= []
  end

  def self.game
    @@game ||= Game.new
  end

  def self.reset!
    @@api_keys = nil
    @@game = nil
  end

  def validate_api_key
    api_key = Rack::Auth::Basic::Request.new(request.env).username
    return false unless api_key

    self.class.game.players.any? { |player| player.api_key == api_key }
  end

  def validate_name?
    params['name'] && params['name'].length > 1
  end

  get '/' do
    @players = self.class.game.players
    slim :index
  end

  post '/join' do
    redirect '/' unless validate_name?

    player = Player.new(params['name'])
    session[:current_player] = player

    self.class.game.add_player(player)

    api_key = SecureRandom.hex(16)
    player.api_key = api_key
    self.class.api_keys << api_key

    respond_to do |f|
      f.html { redirect '/game' }
      f.json { json api_key: api_key }
    end
  end

  get '/game' do
    respond_to do |f|
      f.html do
        redirect '/' if self.class.game.empty? || session[:current_player].nil?
        slim :game,
             locals: { game: self.class.game, current_player: session[:current_player],
                       players: self.class.game.players }
      end
      f.json do
        halt 401, json(error: 'Unauthorized') unless validate_api_key
        # json game: self.class.game
        content_type :json
        game = {
          turn_index: 1,
          players: [
            {
              name: 'Player 1',
              api_key: 'player1apikey',
              hand: [
                { rank: '10', suit: 'hearts' },
                { rank: 'K', suit: 'spades' }
              ],
              books: [
                { rank: 'A', suit: 'hearts' }
              ]
            },
            {
              name: 'Player 2',
              api_key: 'player2apikey',
              hand: [
                { rank: 'Q', suit: 'clubs' },
                { rank: 'J', suit: 'diamonds' }
              ],
              books: [
                { rank: '7', suit: 'spades' }
              ]
            }
          ],
          deck: [
            { rank: '2', suit: 'hearts' },
            { rank: '3', suit: 'spades' },
            { rank: '4', suit: 'clubs' },
            { rank: '5', suit: 'diamonds' }
          ]
        }

        game.to_json
      end
    end
  end
end
