# Require models
require_relative 'seating'
# require_relative 'guest'

Mongo.class_eval do
  class << self
    def db(name)
      name = name.to_s
      @databases ||= {}
      @databases[name] ||= begin
        connection = Mongo::Connection.from_uri(ENV['MONGOLAB_URI'] || 'mongodb://jullunch.dev')
        connection.db name
      end
    end
  end
end
