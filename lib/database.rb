# encoding: UTF-8

# Require models
require 'uri'
require 'time'

require 'mongoid'
require './lib/guest'
require './lib/sitting'
require './lib/import_from_spreadsheet'

Mongoid.load! "mongoid.yml"
