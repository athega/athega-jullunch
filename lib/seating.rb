class Seating
  inherit Mongo::Model

  collection "#{Time.now.year}_seatings"

  attr_accessor :title, :key, :starts_at
end
