require 'sinatra/base'
require "sinatra/reloader"

module Sinatra
  module JullunchHelpers
    def has_valid_token?
      !guest_by_token.nil? && (Time.now.utc < Time.parse('2019-12-11').utc)
    end

    def guest_by_token
      Guest.find_by(token: params[:token]) unless params[:token].nil?
    end

    def guest_by_rfid(rfid = params[:rfid])
      raise Sinatra::NotFound if rfid.nil?
      Guest.find_by(rfid: rfid) or raise Sinatra::NotFound
    end

    def is_coming?
      !guest_by_token.nil? && guest_by_token.coming?
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
end
