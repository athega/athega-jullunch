# encoding: UTF-8

require 'uri'

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
    set :static_cache_control, [:public, :max_age => 300]

    use Rack::Cache,
      :verbose => false,
      :default_ttl => 30,
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

    include Rack::Utils
    alias_method :h, :escape_html
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

  get '/check-in' do
    guests    = Guest.not_arrived_yet.all
    companies = guests.to_a.map(&:company).uniq.sort
    haml :'check_in/index',
      locals: { companies: companies },
      layout: :'check_in/layout'
  end

  get '/check-in/guests' do
    redirect to('/check-in') if params[:company].blank?

    guests = Guest.not_arrived_yet.all_by_company(params[:company])

    haml :'check_in/guests/index',
      locals: { company: params[:company], guests:  guests },
      layout: :'check_in/layout'
  end

  get '/check-in/guests/:token' do
    guest = Guest.by_token(params[:token])

    # Get the latest images
    url  = 'http://assets.athega.se/jullunch/latest_images.json'
    data = Yajl::Parser.parse(RestClient.get(url))

    latest_images = data[0, 8].map { |image| image['url'] }

    haml :'check_in/guests/show',
      locals: { guest: guest, latest_images: latest_images },
      layout: :'check_in/layout'
  end

  post '/rsvp' do
    guest = guest_by_token

    unless guest.nil?
      guest.name        = params[:name]
      guest.company     = params[:company]
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
    haml :about, locals: { page_title: 'Om applikationen - Athega Jullunch' }
  end
end
