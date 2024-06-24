require 'sinatra'
require 'sinatra/json'
require 'sinatra/respond_with'
require 'rack/contrib'
require_relative 'game'
require_relative 'player'

# class Server < Sinatra::Base
#   enable :sessions
#   register Sinatra::RespondWith
#   use Rack::JSONBodyParser
# end


class Server < Sinatra::Base
  enable :sessions
  register Sinatra::RespondWith
  use Rack::JSONBodyParser


  def game
    @@game ||= Game.new
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
      f.html { redirect '/game' }
      f.json { json api_key: api_key }
    end
    
  end

  get '/game' do
    redirect '/' if game.empty?
    respond_to do |f|
      f.html { slim :game, locals: { game: game, current_player: session[:current_player], players: game.players } }
      f.json { json players: game.players }
    end
    
  end
end