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

  # TODO: Reset
  def reset!
  end

  def validate_api_key
    api_key = Rack::Auth::Basic::Request.new(request.env).credentials.first
    return false unless api_key

    game.players.any? { |player| player.api_key == api_key }
  end

  get '/' do
    # TODO: Move get and post into helper methods. def api_get, def api_post
    # get '/game', nil, {
    #   'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64(invalid_api_key + ':X')}",
    #   'HTTP_ACCEPT' => 'application/json'
    # }
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
    # TODO: Check if player is present in the session
    respond_to do |f|
      f.html do
        redirect '/' if game.empty?
        slim :game, locals: { game: game, current_player: session[:current_player], players: game.players }
      end
      f.json do
        halt 401, json(error: 'Unauthorized') unless validate_api_key
        json players: game.players
      end
    end
  end
end
