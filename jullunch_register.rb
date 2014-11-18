# encoding: UTF-8

require_relative 'lib/database'
require_relative 'lib/helpers'

###############################################################################
# Web Application
###############################################################################

class JullunchRegister < Sinatra::Base

  #############################################################################
  # Configuration
  #############################################################################

  configure do
    set :root, File.dirname(__FILE__)

    use Rack::MethodOverride
  end

  configure :production do
    set :static_cache_control, [:public, :max_age => 300]
  end

  helpers Sinatra::JullunchHelpers

  #############################################################################
  # Application routes
  #############################################################################

  ## Arrival
  put '/register/arrival/:rfid' do
    guest = guest_by_rfid

    guest.arrived     = true
    guest.arrived_at  = Time.now.utc if guest.arrived_at.nil?
    guest.save

    public_json_response(guest)
  end

  ## Departure
  put '/register/departure/:rfid' do
    guest = guest_by_rfid

    guest.departed     = true
    guest.departed_at  = Time.now.utc if guest.departed_at.nil?
    guest.save

    public_json_response(guest)
  end

  ## Photo example data:
  # {
  #   "img_name":"abcde.png",
  #   "img_url":"http://s1.uploads.im/abcde.png",
  #   "img_view":"http://uploads.im/abcde.png",
  #   "img_width":167,
  #   "img_height":288,
  #   "img_attr":"width=\"167\" height=\"288\"",
  #   "img_size":"36.1 KB",
  #   "img_bytes":37002,
  #   "thumb_url":"http://s1.uploads.im/t/abcde.png",
  #   "thumb_width":100,
  #   "thumb_height":90,
  #   "source":"http://www.google.com/images/srpr/nav_logo66.png"
  # }
  put '/register/photo/:rfid' do
    guest = guest_by_rfid

    guest.photo = JSON.parse request.body.read
    guest.save

    public_json_response(guest)
  end

  ## Action
  put %r{/register/action/(mulled_wine|food|drink|coffee)/([\w-]+)} do |action, rfid|
    guest = guest_by_rfid rfid

    guest.instance_variable_set("@#{action}", guest.instance_variable_get("@#{action}").to_i + 1)
    guest.save

    public_json_response(guest)
  end
  
end
