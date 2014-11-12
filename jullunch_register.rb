# encoding: UTF-8

require_relative 'lib/database'
require_relative 'lib/notification'

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

  #############################################################################
  # Helpers
  #############################################################################

  helpers do
    def public_json_response(obj)
      content_type 'application/json', :charset => 'utf-8'
      response['Access-Control-Allow-Origin'] = '*'

      Yajl::Encoder.encode(obj)
    end
  end

  #############################################################################
  # Application routes
  #############################################################################

  put '/register/arrival/:rfid' do
    guest = Guest.by_rfid(params[:rfid])

    unless guest.nil?
      guest.arrived     = true
      guest.arrived_at  = Time.now.utc if guest.arrived_at.nil?
      guest.save
    end

    public_json_response(guest)
  end
end
