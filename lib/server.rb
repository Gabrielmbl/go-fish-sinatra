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

  def api_keys
    @api_keys ||= []
  end

  def game
    @@game ||= Game.new
  end

  def validate_api_key
    api_key = Rack::Auth::Basic::Request.new(request.env).credentials.first
    return false unless api_key

    game.players.any? { |player| player.api_key == api_key }
  end

  get '/' do
    @players = game.players
    slim :index
  end

  post '/join' do
    player = Player.new(params['name'])
    session[:current_player] = player

    game.add_player(player)

    api_key = SecureRandom.hex(16)
    player.api_key = api_key
    api_keys << api_key

    respond_to do |f|
      f.html { redirect '/game' }
      f.json { json api_key: api_key }
    end
  end

  get '/game' do
    respond_to do |f|
      f.html do
        redirect '/' if game.empty? || session[:current_player].nil?
        slim :game, locals: { game: game, current_player: session[:current_player], players: game.players }
      end
      f.json do
        halt 401, json(error: 'Unauthorized') unless validate_api_key
        json players: game.players
      end
    end
  end
end
