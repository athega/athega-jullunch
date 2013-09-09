require 'bundler'
Bundler.require

ENV['MEMCACHE_SERVERS']  = ENV['MEMCACHIER_SERVERS']
ENV['MEMCACHE_USERNAME'] = ENV['MEMCACHIER_USERNAME']
ENV['MEMCACHE_PASSWORD'] = ENV['MEMCACHIER_PASSWORD']

require './jullunch.rb'

use Rack::Deflater

run Jullunch
