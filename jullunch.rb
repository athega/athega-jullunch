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
      Guest.by_token(params[:token])
    end
  end

  #############################################################################
  # Application routes
  #############################################################################

  get '/' do
    sittings = Sitting.sort([:starts_at, -1]).all

    haml :index, locals: {
      page_title: 'Athega Jullunch',
      sittings: sittings
    }
  end

  get '/prepare_db_qwerty1234' do
    Sitting.delete_all

    Sitting.new(key: 1130, title: '11:30', starts_at: Time.parse('2011-12-16 11:30:00 CET').utc).save
    Sitting.new(key: 1200, title: '12:00', starts_at: Time.parse('2011-12-16 12:00:00 CET').utc).save
    Sitting.new(key: 1230, title: '12:30', starts_at: Time.parse('2011-12-16 12:30:00 CET').utc).save
    Sitting.new(key: 1300, title: '13:00', starts_at: Time.parse('2011-12-16 13:00:00 CET').utc).save
    Sitting.new(key: 1330, title: '13:30', starts_at: Time.parse('2011-12-16 13:30:00 CET').utc).save
    Sitting.new(key: 0000, title: 'Jag måste tyvärr tacka nej').save

    Guest.delete_all

    Guest.new name: 'Peter',   company: 'Code7', email: 'peter@c7.se', invited_by: 'Peter'
    Guest.new name: 'Peter 1', company: 'Code7', email: 'peter@c7.se', invited_by: 'Peter'
    Guest.new name: 'Peter 2', company: 'Code7', email: 'peter@c7.se', invited_by: 'Peter'
    Guest.new name: 'Peter 3', company: 'Code7', email: 'peter@c7.se', invited_by: 'Peter'
    Guest.new name: 'Peter 4', company: 'Code7', email: 'peter@c7.se', invited_by: 'Peter'
  end


  get '/rsvp' do
    haml :rsvp, :locals => { :page_title => 'Tack - Athega Jullunch' }
  end

  get '/about' do
    haml :about, :locals => { :page_title => 'Om applikationen - Athega Jullunch' }
  end
end
