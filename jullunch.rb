# encoding: UTF-8

require_relative 'lib/database'
require_relative 'jullunch_admin'

###############################################################################
# Web Application
###############################################################################

class Jullunch < Sinatra::Base

  #############################################################################
  # Configuration
  #############################################################################

  configure do
    set :root, File.dirname(__FILE__)
  end

  configure :production do
    use Rack::Cache,
      :verbose => false,
      :metastore => "memcached://#{ENV['MEMCACHE_SERVERS']}",
      :entitystore => "memcached://#{ENV['MEMCACHE_SERVERS']}"
  end

  #############################################################################
  # Admin
  #############################################################################

  use JullunchAdmin

  #############################################################################
  # Helpers
  #############################################################################

  helpers do
    def has_valid_token?
      !guest_by_token.nil?
    end

    def guest_by_token
      Guest.by_token(params[:token]) unless params[:token].nil?
    end
  end

  #############################################################################
  # Application routes
  #############################################################################

  get '/' do
    sittings = Sitting.sort([:starts_at, 1]).all

    haml :index, locals: {
      page_title: 'Athega Jullunch', sittings: sittings, guest: guest_by_token
    }
  end

  post '/rsvp' do
    guest = guest_by_token

    unless guest.nil?
      guest.name        = params[:name]
      guest.company     = params[:company]
      guest.email       = params[:email]
      guest.sitting_key = params[:sitting_key].to_i

      if guest.valid?
        guest.save
        redirect to("/?token=#{guest.token}&rsvp=true")
      end
    end

    redirect to("/?token=#{params[:token]}")
  end

  get '/about' do
    cache_control :public, :max_age => 5

    haml :about, :locals => { :page_title => 'Om applikationen - Athega Jullunch' }
  end
end
