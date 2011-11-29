require 'bundler'
Bundler.require

require './jullunch.rb'

use Rack::Deflater

run Jullunch
