require 'sinatra'
require 'sinatra/json'
require 'sinatra/respond_with'
require 'rack/contrib'
# require_relative 'lib/game'
# require_relative 'lib/player'

# class Server < Sinatra::Base
#   enable :sessions
#   register Sinatra::RespondWith
#   use Rack::JSONBodyParser
# end


class Server < Sinatra::Base
  enable :sessions
  register Sinatra::RespondWith
  use Rack::JSONBodyParser

  players = []

  def self.game
    @@game ||= Game.new
  end

  get '/' do
    @players = players
    slim :index
  end

  post '/join' do
    player = params['name']
    session[:current_player] = player
    # self.class.game.add_player(player)
    players << player unless players.include?(player)
    redirect '/'
    # redirect '/game'
  end

  # get '/game' do
  #   redirect '/' if self.class.game.empty?
  #   slim :game, locals: { game: self.class.game, current_player: session[:current_player] }
  # end
end