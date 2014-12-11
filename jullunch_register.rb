# encoding: utf-8

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
    set :subscribers => []

    use Rack::MethodOverride
  end

  configure :production do
    set :static_cache_control, [:public, :max_age => 300]
  end

  helpers Sinatra::JullunchHelpers

  helpers do
    def send_to_event_stream(event, data, id=nil)
      settings.subscribers.each { |out|
        out << "id: #{id}\n" if id
        out << "event: #{event}\n"
        out << "data: #{data}\n\n"
      }
    end
  end

  #############################################################################
  # Keep the event stream alive
  #############################################################################
  Thread.new do
    while true do
      sleep 20
      settings.subscribers.each { |out| out << ": hearbeat\n\n" }
    end
  end

  #############################################################################
  # Application routes
  #############################################################################

  ## Arrival
  put '/register/arrival/:rfid' do
    guest = Guest.by_rfid(params[:rfid])

    # If using untagged card, see if there are any untagged check-ins
    if guest.nil?
      guest = Guest.arrived.untagged.first
      unless guest.nil?
        guest.rfid = params[:rfid]
      else
        raise Sinatra::NotFound
      end
    end

    guest.arrived     = true
    guest.arrived_at  = Time.now.utc if guest.arrived_at.nil?
    guest.save

    send_to_event_stream('arrival', Yajl::Encoder.encode(guest))
    send_to_event_stream('arrived', Guest.arrived.count)
    send_to_event_stream('arrived-company', Guest.all_by_company(guest.company).count)
    public_json_response(guest)
  end

  ## Departure
  put '/register/departure/:rfid' do
    guest = guest_by_rfid

    guest.departed     = true
    guest.departed_at  = Time.now.utc if guest.departed_at.nil?
    guest.save

    send_to_event_stream('departure', Yajl::Encoder.encode(guest))
    send_to_event_stream('departed', Guest.departed.count)
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
    guest.image_url = guest.photo["data"]["img_url"]
    guest.save

    send_to_event_stream('photo', Yajl::Encoder.encode(guest))
    public_json_response(guest)
  end

  ## Action
  put %r{/register/action/(mulled_wine|food|drink|coffee)/([\w-]+)} do |action, rfid|
    guest = guest_by_rfid rfid

    guest.instance_variable_set("@#{action}", guest.instance_variable_get("@#{action}").to_i + 1)
    guest.save

    send_to_event_stream(action, Guest.all.map { |g| g.instance_variable_get("@#{action}").to_i }.reduce(:+))
    public_json_response(guest)
  end

  ## Tag
  put '/register/tag/:rfid' do
    raise Sinatra::NotFound if params[:rfid].nil?

    guest = Guest.by_rfid(params[:rfid])
    message = 'Alla gäster är taggade!';

    if guest
      message = 'var redan taggad'
    else
      untagged = Guest.said_yes.untagged.first
      if untagged
        untagged.rfid = params[:rfid]
        untagged.save

        message = 'har taggats med'
        guest = untagged;
      end
    end

    send_to_event_stream('untagged', Guest.said_yes.untagged.count)
    send_to_event_stream('tag', "{\"message\": \"#{message}\", \"guest\": #{Yajl::Encoder.encode(guest)}}")
    public_json_response(guest)
  end

  ## Data
  get '/register/data' do
    guests = Guest.all
    public_json_response({
      arrived:     Guest.arrived.count,
      departed:    Guest.departed.count,
      rsvped:      Guest.said_yes.count,
      mulled_wine: guests.map { |g| g.mulled_wine.to_i }.reduce(:+),
      food:        guests.map { |g| g.food.to_i }.reduce(:+),
      drink:       guests.map { |g| g.drink.to_i }.reduce(:+),
      coffee:      guests.map { |g| g.coffee.to_i }.reduce(:+)
    })
  end

  ## Event stream
  get '/register/events', provides: 'text/event-stream' do
    response['Access-Control-Allow-Origin'] = '*'
    stream :keep_open do |out|
      out << "event: init\n"
      out << "data: there are now #{settings.subscribers.count+1} stream(s).\n\n"
      settings.subscribers << out
      out.callback { settings.subscribers.delete(out) }
    end
  end

  options '/register/events' do
    response['Access-Control-Allow-Origin'] = '*'
  end

end
