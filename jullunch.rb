# encoding: UTF-8

require_relative 'jullunch_admin.rb'

class Jullunch < Sinatra::Base
  set :root, File.dirname(__FILE__)

  use JullunchAdmin

  get '/' do
    'Jullunch'
  end
end
