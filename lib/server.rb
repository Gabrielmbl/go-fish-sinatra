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

  def start_game_if_possible
    return if self.class.game.started

    self.class.game.start if self.class.game.players.count >= Game::MIN_PLAYERS
  end

  def validate_api_key
    api_key = Rack::Auth::Basic::Request.new(request.env).username
    return false unless api_key

    self.class.game.players.any? { |player| player.api_key == api_key }
  end

  def validate_name?
    params['name'] && params['name'].length > 1
  end

  def create_player
    player = Player.new(params['name'])
    session[:current_player] = player

    self.class.game.add_player(player)
    self.class.api_keys << player.api_key
    player
  end

  get '/' do
    @players = self.class.game.players
    slim :index
  end

  post '/join' do
    redirect '/' unless validate_name?

    player = create_player

    start_game_if_possible

    respond_to do |f|
      f.html { redirect '/game' }
      f.json { json api_key: player.api_key }
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
        json self.class.game.as_json
      end
    end
  end
  # post '/game' do
  # end
end
