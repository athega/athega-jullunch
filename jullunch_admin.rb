# encoding: UTF-8

require_relative 'lib/database'
require_relative 'lib/notification'

###############################################################################
# Web Application
###############################################################################

class JullunchAdmin < Sinatra::Base

  use Rack::MethodOverride

  use Rack::Session::Cookie, key:    'athega_jullunch',
                             secret: 'Knowledge is power and true Sith do not share power.'

  #############################################################################
  # Configuration
  #############################################################################

  configure do
    set :root, File.dirname(__FILE__)
    set :sessions, true
  end

  configure :development do
    set :forced_authentication, true
  end

  configure :production do
    set :static_cache_control, [:public, :max_age => 300]

    require 'openid'

    OpenID.fetcher.ca_file = './config/ca-bundle.crt'

    require 'openid/store/filesystem'

    use OmniAuth::Strategies::GoogleApps,
        OpenID::Store::Filesystem.new('./tmp'),
          :name   => 'athega',
          :domain => 'athega.se'
  end

  helpers do
    def logged_in?
      return true if settings.respond_to?(:forced_authentication)
      !session[:current_user_email].nil?
    end

    include Rack::Utils
    alias_method :h, :escape_html
  end

  before /\/admin.*/ do
    redirect '/auth/athega' unless logged_in?
  end

  #############################################################################
  # Authentication routes
  #############################################################################

  post '/auth/:name/callback' do
    auth = request.env['omniauth.auth']
    session[:current_user_email] = auth['user_info']['email']
    redirect '/admin'
  end

  get '/auth/logout' do
    session.clear
    redirect '/'
  end

  get '/logout/?' do
    redirect '/auth/logout'
  end

  get '/login/?' do
    redirect '/auth/athega'
  end

  #############################################################################
  # Application routes
  #############################################################################

  get '/admin/?' do
    redirect to('/admin/guests')
  end

  get '/admin/guests' do

    statistics = [
      OpenStruct.new(text: 'TOTALT:',       count: Guest.count),
      OpenStruct.new(text: 'Inbjudningar:', count: Guest.invited.count),
      OpenStruct.new(text: 'Manuella:',     count: Guest.invited_manually.count),
      OpenStruct.new(text: '11:30:',        count: Guest.all_by_sitting_key(1130).count),
      OpenStruct.new(text: '12:00:',        count: Guest.all_by_sitting_key(1200).count),
      OpenStruct.new(text: '12:30:',        count: Guest.all_by_sitting_key(1230).count),
      OpenStruct.new(text: '13:00:',        count: Guest.all_by_sitting_key(1300).count),
      OpenStruct.new(text: '13:30:',        count: Guest.all_by_sitting_key(1330).count),
      OpenStruct.new(text: 'Tackat nej:',   count: Guest.all_by_sitting_key(0).count),
      OpenStruct.new(text: 'Ej valt:',      count: Guest.all_by_sitting_key(nil).count),
    ]

    haml :'admin/guests/index', locals: {
      page_title: 'Gäster - Athega Jullunch',
      guests: Guest.sort([:company, 1], [:name, 1]).all,
      statistics: statistics
    }
  end

  post '/admin/guests/import_from_spreadsheet' do
    import_count = ImportFromSpreadsheet.guests!
    redirect to("/admin/guests?number_of_imported_guests=#{import_count}")
  end

  post '/admin/guests' do
    guest = Guest.new name:             params[:name],
                      company:          params[:company],
                      email:            params[:email],
                      invited_by:       params[:invited_by],
                      invited_manually: (params[:invited_manually] == 'yes')

    guest.save if guest.valid?

    redirect '/admin/guests'
  end

  delete '/admin/guests/:token' do
    guest = Guest.by_token(params[:token])

    guest.delete unless guest.nil?

    redirect to('/admin/guests')
  end

  get '/admin/sittings' do
    haml :'admin/sittings', locals: {
      page_title: 'Sittningar - Athega Jullunch',
      sittings: Sitting.sort([:starts_at, -1]).all
    }
  end

  post '/admin/sittings' do
    sitting = Sitting.by_key(params[:key].to_i)

    if sitting.nil?
      sitting = Sitting.new

      sitting.key                      = params[:key].to_i
      sitting.title                    = params[:title]
      sitting.starts_at                = Time.parse(params[:starts_at]).utc
      sitting.number_of_guests_allowed = params[:number_of_guests_allowed].to_i
      sitting.number_of_reserved_seats = params[:number_of_reserved_seats].to_i

      sitting.save
    end

    redirect to('/admin/sittings')
  end

  post '/admin/sittings/:key' do
    sitting = Sitting.by_key(params[:key].to_i)

    unless sitting.nil?
      if params[:title].empty? || params[:starts_at].empty?
        sitting.delete
      else
        sitting.title = params[:title]
        sitting.starts_at = Time.parse(params[:starts_at]).utc
        sitting.number_of_guests_allowed = params[:number_of_guests_allowed].to_i
        sitting.number_of_reserved_seats = params[:number_of_reserved_seats].to_i
        sitting.save
      end
    end

    redirect to('/admin/sittings')
  end

  get '/admin/notifications' do
    haml :'admin/notifications', locals: {
      page_title: 'Notifikationer - Athega Jullunch'
    }
  end

  post '/admin/notifications/send_all_pending_invitations' do
    sent_count = Notification.send_all_pending_invitations!
    redirect to("/admin/notifications?number_of_invitations_sent=#{sent_count}")
  end

  post '/admin/notifications/send_all_pending_thank_you_notes' do
    sent_count = Notification.send_all_pending_thank_you_notes!
    redirect to("/admin/notifications?number_of_thank_you_notes_sent=#{sent_count}")
  end

  get '/admin/prepare_db_qwerty1234' do
    Sitting.delete_all

    number_of_guests_allowed = params[:number_of_guests_allowed].to_i
    number_of_reserved_seats = params[:number_of_reserved_seats].to_i

    Sitting.new(key: 1130, title: '11:30', starts_at: Time.parse('2013-12-13 11:30:00 CET').utc, 
                number_of_guests_allowed: number_of_guests_allowed, number_of_reserved_seats: number_of_reserved_seats).save
    Sitting.new(key: 1200, title: '12:00', starts_at: Time.parse('2013-12-13 12:00:00 CET').utc,
                number_of_guests_allowed: number_of_guests_allowed, number_of_reserved_seats: number_of_reserved_seats).save
    Sitting.new(key: 1230, title: '12:30', starts_at: Time.parse('2013-12-13 12:30:00 CET').utc,
                number_of_guests_allowed: number_of_guests_allowed, number_of_reserved_seats: number_of_reserved_seats).save
    Sitting.new(key: 1230, title: '12:30', starts_at: Time.parse('2013-12-13 12:30:00 CET').utc,
                number_of_guests_allowed: number_of_guests_allowed, number_of_reserved_seats: number_of_reserved_seats).save
    Sitting.new(key: 1300, title: '13:00', starts_at: Time.parse('2013-12-13 13:00:00 CET').utc,
                number_of_guests_allowed: number_of_guests_allowed, number_of_reserved_seats: number_of_reserved_seats).save
    Sitting.new(key: 1330, title: '13:30', starts_at: Time.parse('2013-12-13 13:30:00 CET').utc,
                number_of_guests_allowed: number_of_guests_allowed, number_of_reserved_seats: number_of_reserved_seats).save
    Sitting.new(key: 0000, title: 'Jag måste tyvärr tacka nej').save

    redirect '/admin/guests'
  end

  get '/admin/load_test_users_qwerty1234' do
    import_count = ImportFromSpreadsheet.test!
    redirect "/admin/guests?imported_test_users=#{import_count}"
  end
end
