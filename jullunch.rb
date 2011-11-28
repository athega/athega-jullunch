# encoding: UTF-8

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

  configure :development do
    set :db_name, 'athega_jullunch'
  end

  configure :production do
    set :db_name, URI.parse(ENV['MONGOLAB_URI']).path.gsub(/^\//, '')
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
      true
    end
  end

  #############################################################################
  # Application routes
  #############################################################################

  before do
    Mongo::Model.default_database_name = settings.db_name
  end

  get '/' do
    Seating.db.clear

    Seating.new(key: 1130, title: 'Ankomsttid - 11:30', starts_at: Time.parse('2011-12-16 11:30:00 CET').utc).save
    Seating.new(key: 1200, title: 'Ankomsttid - 12:00', starts_at: Time.parse('2011-12-16 12:00:00 CET').utc).save
    Seating.new(key: 1230, title: 'Ankomsttid - 12:30', starts_at: Time.parse('2011-12-16 12:30:00 CET').utc).save
    Seating.new(key: 1300, title: 'Ankomsttid - 13:00', starts_at: Time.parse('2011-12-16 13:00:00 CET').utc).save
    Seating.new(key: 1330, title: 'Ankomsttid - 13:30', starts_at: Time.parse('2011-12-16 13:30:00 CET').utc).save
    Seating.new(key: 0000, title: 'Jag måste tyvärr tacka nej').save

    seatings = [
      Seating.db.name,
      Seating.collection.name,
      Seating.db.inspect,
      Seating.sort([:starts_at, -1]).all
    ]

    haml :index, :locals => { :page_title => 'Athega Jullunch', :seatings => seatings }
  end

  get '/rsvp' do
    haml :rsvp, :locals => { :page_title => 'Tack - Athega Jullunch' }
  end

  get '/about' do
    haml :about, :locals => { :page_title => 'Om applikationen - Athega Jullunch' }
  end
end
