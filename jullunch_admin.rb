# encoding: UTF-8

require 'openid'
require 'openid/store/filesystem'
require 'omniauth/openid'

class JullunchAdmin < Sinatra::Base
  set :root, File.dirname(__FILE__)

  helpers do
    def logged_in?
      !session[:current_user_email].nil?
    end
  end

  before /\/admin.*/ do
    redirect '/auth/athega' unless logged_in?
  end

  configure do |m|
    set :sessions, true
  end

  OpenID.fetcher.ca_file = './config/ca-bundle.crt'

  use Rack::Session::Cookie, :key    => 'athega_jullunch',
                             :secret => 'Knowledge is power and true Sith do not share power.'

  use OmniAuth::Strategies::GoogleApps,
        OpenID::Store::Filesystem.new('/tmp'),
          :name   => 'athega',
          :domain => 'athega.se'

  post '/auth/:name/callback' do
    auth = request.env['omniauth.auth']
    session[:current_user_email] = auth['user_info']['email']
    redirect '/admin'
  end

  get '/auth/logout' do
    session.clear
    redirect '/'
  end

  get '/auth/failure' do
    # Add an error message :)
    redirect '/'
  end

  get '/logout/?' do
    redirect '/auth/logout'
  end

  get '/login/?' do
    redirect '/auth/athega'
  end

  get '/admin' do
    Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://development.db') do |db|
    end

    'Jullunch ADMIN!' + session[:current_user_email]
  end
end
