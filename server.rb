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
  def self.game
    @@game ||= Game.new
  end
  get '/' do
    slim :index
  end
end
