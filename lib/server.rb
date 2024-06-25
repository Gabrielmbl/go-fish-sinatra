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

  def game
    @@game ||= Game.new
  end

  def validate_api_key
    auth_header = request.env['HTTP_AUTHORIZATION'] || session[:http_authorization]
    return false unless auth_header

    encoded_key = auth_header.split(' ').last
    decoded_key = Base64.decode64(encoded_key).split(':').first

    game.players.any? { |player| player.api_key == decoded_key }
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

    respond_to do |f|
      f.html do
        session[:http_authorization] = "Basic #{Base64.encode64(api_key + ':X')}"
        redirect '/game'
      end
      f.json { json api_key: api_key }
    end
  end

  get '/game' do
    halt 401, json(error: 'Unauthorized') unless validate_api_key

    redirect '/' if game.empty?
    respond_to do |f|
      f.html { slim :game, locals: { game: game, current_player: session[:current_player], players: game.players } }
      f.json { json players: game.players }
    end
  end
end
