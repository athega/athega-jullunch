require "bundler/setup"

task :default => :irb

task :irb do
  require 'irb'
  require './lib/database.rb'
  
  ARGV.clear
  IRB.start
end
