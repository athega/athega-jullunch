# encoding: UTF-8

require 'uri'
require 'digest/md5'

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

    use Rack::MethodOverride
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

    def gravatar(email)
      hash = Digest::MD5.hexdigest(email.downcase)
      "http://www.gravatar.com/avatar/#{hash}?d=mm&s=50"
    end

    def uri_escape(str)
      URI.escape(str).gsub('+', '%2B')
    end

    def public_json_response(obj)
      content_type 'application/json', :charset => 'utf-8'
      response['Access-Control-Allow-Origin'] = '*'

      Yajl::Encoder.encode(obj)
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

  get '/data/latest_check_ins.json' do
    guests = Guest.arrived.limit(20).sort([:arrived_at, -1]).all.to_a
    public_json_response(guests)
  end

  get '/arrived_guests' do
    arrived_guests = Guest.arrived.sort([:name, 1]).all
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

    arrived_guests = Guest.arrived.sort([:name, 1]).
                                   all_by_company(params[:company])

    guests = Guest.not_arrived_yet.sort([:name, 1]).
                                   all_by_company(params[:company])

    if params[:guests] == 'all'
      guests = Guest.all_by_company(params[:company])
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
    guest = Guest.by_token(params[:token])

    # Get all images
    url  = 'http://assets.athega.se/jullunch/all_images.json'

    data = Yajl::Parser.parse(RestClient.get(url))

    all_images = data.map { |image| image['url'] }

    haml :'check_in/guests/show',
      locals: { guest: guest, all_images: all_images },
      layout: :'check_in/layout'
  end

  put '/check-in/guests/:token' do
    guest = Guest.by_token(params[:token])

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

  #############################################################################
  # Backbone.js app routes
  #############################################################################

  ['/loop', '/ads', '/check-ins', '/images', '/tweets'].each do |path|
    get path do
      haml :backbone, :layout => false
    end
  end
end
