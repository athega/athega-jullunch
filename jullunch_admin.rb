# encoding: UTF-8

require 'openid'
require 'openid/store/filesystem'

require_relative 'lib/database'

###############################################################################
# Web Application
###############################################################################

class JullunchAdmin < Sinatra::Base

  OpenID.fetcher.ca_file = './config/ca-bundle.crt'

  use Rack::Session::Cookie, :key    => 'athega_jullunch',
                             :secret => 'Knowledge is power and true Sith do not share power.'

  #############################################################################
  # Configuration
  #############################################################################

  configure do
    set :root, File.dirname(__FILE__)
    set :sessions, true
  end

  configure :development do
    set :mongodb_uri, 'mongodb://localhost'
    set :mongodb_database, 'athega_jullunch'
    set :forced_authentication, true
  end

  configure :production do
    mongodb_uri = URI.parse(ENV['MONGOLAB_URI'])
    set :mongodb_uri, mongodb_uri.to_s
    set :mongodb_database, mongodb_uri.path.gsub(/^\//, '')

    use OmniAuth::Strategies::GoogleApps,
        OpenID::Store::Filesystem.new('/tmp'),
          :name   => 'athega',
          :domain => 'athega.se'

  end

  helpers do
    def logged_in?
      return true unless settings.forced_authentication.nil?
      !session[:current_user_email].nil?
    end
  end

  before /\/admin.*/ do
    redirect '/auth/athega' unless logged_in?

    conn  = Mongo::Connection.from_uri(settings.mongodb_uri)
    @db   = conn.db(settings.mongodb_database)
  end

  #############################################################################
  # Authentication routes
  #############################################################################

  post '/auth/:name/callback' do
    auth = request.env['omniauth.auth']
    session[:current_user_email] = auth['user_info']['email']
    redirect '/admin'
  end

  get '/auth/logout' do
    session.clear
    redirect '/'
  end

  get '/logout/?' do
    redirect '/auth/logout'
  end

  get '/login/?' do
    redirect '/auth/athega'
  end

  #############################################################################
  # Application routes
  #############################################################################

  get '/admin/?' do
    redirect to('/admin/guests')
  end

  get '/admin/guests' do
    # Guest.new()

    haml :'admin/guests/index', locals: {
      page_title: 'Gäster - Athega Jullunch',
      guests: Guest.sort([:starts_at, -1]).all
    }
  end

  get '/admin/seatings' do
    haml :'admin/seatings', locals: {
      page_title: 'Sittningar - Athega Jullunch',
      seatings: Seating.sort([:starts_at, -1]).all
    }
  end

  post '/admin/seatings' do
    seating = Seating.by_key(params[:key].to_i)

    if seating.nil?
      seating = Seating.new

      seating.key       = params[:key].to_i
      seating.title     = params[:title]
      seating.starts_at = Time.parse(params[:starts_at]).utc

      seating.save
    end

    redirect to('/admin/seatings')
  end

  post '/admin/seatings/:key' do
    seating = Seating.by_key(params[:key].to_i)

    unless seating.nil?
      if params[:title].empty? || params[:starts_at].empty?
        seating.delete
      else
        seating.title = params[:title]
        seating.starts_at = Time.parse(params[:starts_at]).utc
        seating.save
      end
    end

    redirect to('/admin/seatings')
  end

  get '/admin/notifications' do
    haml :'admin/notifications', locals: {
      page_title: 'Notifikationer - Athega Jullunch'
    }
  end
end
