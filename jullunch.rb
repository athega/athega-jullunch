# encoding: utf-8

require 'uri'
require 'digest/md5'

require_relative 'lib/database'
require_relative 'lib/helpers'
require_relative 'jullunch_admin'
require_relative 'jullunch_register'

###############################################################################
# Web Application
###############################################################################

class Jullunch < Sinatra::Base

  #############################################################################
  # Configuration
  #############################################################################

  configure do
    set :root, File.dirname(__FILE__)

    use Rack::MethodOverride
  end

  configure :development do
    register Sinatra::Reloader
  end

  configure :production do
    set :static_cache_control, [:public, :max_age => 300]

    use Rack::Cache,
      :verbose => false,
      :default_ttl => 30,
      :metastore => "memcached://#{ENV['MEMCACHE_SERVERS']}",
      :entitystore => "memcached://#{ENV['MEMCACHE_SERVERS']}"
  end

  helpers Sinatra::JullunchHelpers

  #############################################################################
  # Admin
  #############################################################################

  use JullunchAdmin

  #############################################################################
  # Register
  #############################################################################

  use JullunchRegister

  #############################################################################
  # Application routes
  #############################################################################

  get '/' do
    sittings = Sitting.order_by(:starts_at.asc).all

    haml :index, locals: {
      page_title: 'Athega Jullunch', sittings: sittings, guest: guest_by_token
    }
  end

  get '/data/latest_check_ins.json' do
    guests = Guest.arrived.limit(20).order_by(:arrived_at.desc).all.to_a
    public_json_response(guests)
  end

  get '/arrived_guests' do
    arrived_guests = Guest.arrived.order_by(:name.asc)
    haml :arrived_guests, locals: {
      arrived_guests: arrived_guests,
      page_title: 'Alla gäster på Jullunchen'
    }
  end

  get '/check-in' do
   guests = Guest.all

    companies = guests.to_a.map(&:company).uniq.sort
    haml :'check_in/index',
      locals: { companies: companies },
      layout: :'check_in/layout'
  end

  get '/check-in/guests' do
    redirect to('/check-in') if params[:company].blank?

    arrived_guests = Guest.arrived.order_by(:name.asc).where(company: params[:company])

    guests = Guest.not_arrived_yet.order_by(:name.asc).where(company: params[:company])

    if params[:guests] == 'all'
      guests = Guest.find_by(company: params[:company])
    end

    haml :'check_in/guests/index',
      locals: {
        company: params[:company],
        guests:  guests,
        arrived_guests: arrived_guests
      },
      layout: :'check_in/layout'
  end

  get '/check-in/guests/:token' do
    guest = Guest.find_by(token: params[:token])

    # Get all images
    url  = 'http://assets.athega.se/jullunch/all_images.json'

    data = Yajl::Parser.parse(RestClient.get(url))

    all_images = data.map { |image| image['url'] }

    haml :'check_in/guests/show',
      locals: { guest: guest, all_images: all_images },
      layout: :'check_in/layout'
  end

  put '/check-in/guests/:token' do
    guest = Guest.find_by(token: params[:token])

    unless guest.nil?
      guest.image_url   = params[:image_url]
      guest.arrived     = true
      guest.arrived_at  = Time.now.utc if guest.arrived_at.nil?
      guest.save
    end

    redirect to('/check-in')
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

  get '/companies.json' do
    content_type 'application/json', :charset => 'utf-8'
    guests = Guest.all
    companies = guests.group_by(&:company)

    Yajl::Encoder.encode(companies)
  end

  get '/guest.json' do
    guest = guest_by_token
    guest = guest_by_rfid if guest.nil?

    public_json_response(guest)
  end

  #############################################################################
  # Backbone.js app routes
  #############################################################################

  ['/loop', '/ads', '/check-ins', '/images', '/tweets'].each do |path|
    get path do
      haml :backbone, :layout => false
    end
  end
end
