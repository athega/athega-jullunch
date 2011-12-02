# encoding: UTF-8

# Require models
require 'uri'
require 'time'
require 'mongo/model'

require './lib/guest'
require './lib/sitting'
require './lib/import_from_spreadsheet'

db_name = 'athega_jullunch'

if ENV['MONGOLAB_URI']
  db_name = URI.parse(ENV['MONGOLAB_URI']).path.gsub(/^\//, '')
end

Mongo::Model.default_database_name = db_name

Mongo.class_eval do
  class << self
    def db(name)
      name = name.to_s
      @databases ||= {}
      @databases[name] ||= begin
        connection = Mongo::Connection.from_uri(ENV['MONGOLAB_URI'] || 'mongodb://localhost')
        connection.db name
      end
    end
  end
end
