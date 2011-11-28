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

  use OmniAuth::Strategies::GoogleApps,
        OpenID::Store::Filesystem.new('/tmp'),
          :name   => 'athega',
          :domain => 'athega.se'

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
  end

  configure :production do
    mongodb_uri = URI.parse(ENV['MONGOLAB_URI'])
    set :mongodb_uri, mongodb_uri.to_s
    set :mongodb_database, mongodb_uri.path.gsub(/^\//, '')
  end

  helpers do
    def logged_in?
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

  get '/admin' do
    collections = []

    @db.collection_names.each { |name| collections << name }

    'Jullunch ADMIN!' + session[:current_user_email] + settings.mongodb_database + collections.join(':')
  end
end
