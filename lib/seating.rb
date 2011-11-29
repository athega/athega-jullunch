class Seating
  inherit Mongo::Model

  collection "#{Time.now.year}_seatings"

  attr_accessor :title, :key, :starts_at

  validates_numericality_of :key
  validates_presence_of :title

  def local_time
    starts_at.nil? ? '' : starts_at.getlocal
  end
end
