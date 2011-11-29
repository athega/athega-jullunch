# encoding: UTF-8

require_relative 'lib/database'

###############################################################################
# Web Application
###############################################################################

class JullunchAdmin < Sinatra::Base

  use Rack::Session::Cookie, key:    'athega_jullunch',
                             secret: 'Knowledge is power and true Sith do not share power.'

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
    require 'openid'

    OpenID.fetcher.ca_file = './config/ca-bundle.crt'

    require 'openid/store/filesystem'

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
      return true if settings.respond_to?(:forced_authentication)
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
    haml :'admin/guests/index', locals: {
      page_title: 'Gäster - Athega Jullunch',
      guests: Guest.sort([:starts_at, -1]).all
    }
  end

  post '/admin/guests' do
    guest = Guest.new name:       params[:name],
                      company:    params[:company],
                      phone:      params[:phone],
                      email:      params[:email],
                      invited_by: params[:invited_by]

    guest.save if guest.valid?

    redirect '/admin/guests'
  end

  get '/admin/sittings' do
    haml :'admin/sittings', locals: {
      page_title: 'Sittningar - Athega Jullunch',
      sittings: Sitting.sort([:starts_at, -1]).all
    }
  end

  post '/admin/sittings' do
    sitting = Sitting.by_key(params[:key].to_i)

    if sitting.nil?
      sitting = Sitting.new

      sitting.key       = params[:key].to_i
      sitting.title     = params[:title]
      sitting.starts_at = Time.parse(params[:starts_at]).utc

      sitting.save
    end

    redirect to('/admin/sittings')
  end

  post '/admin/sittings/:key' do
    sittings = Sitting.by_key(params[:key].to_i)

    unless sitting.nil?
      if params[:title].empty? || params[:starts_at].empty?
        sitting.delete
      else
        sitting.title = params[:title]
        sitting.starts_at = Time.parse(params[:starts_at]).utc
        sitting.save
      end
    end

    redirect to('/admin/sittings')
  end

  get '/admin/notifications' do
    haml :'admin/notifications', locals: {
      page_title: 'Notifikationer - Athega Jullunch'
    }
  end
end
