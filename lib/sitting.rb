# encoding: UTF-8

class Sitting
  include Mongoid::Document

  SEAT_COUNT_DOWN_THRESHOLD = 10

  store_in collection: "sittings_#{Time.now.year}"

  field :title
  field :key
  field :starts_at
  field :number_of_guests_allowed
  field :number_of_reserved_seats

  validates_numericality_of :key
  validates :title, presence: true

  scope :by_key, -> (id) { where(key: id) }

  def local_time
    starts_at.nil? ? '' : starts_at.getlocal
  end

  def guest_count
    return 0
#    Guest.count(sitting_key: key)
  end

  def guest_status_class
    return 'sitting' if key == 0
    return 'sitting red' if full?

    case guest_count
      when  0..8 then 'sitting green'
      when  9..15 then 'sitting yellow'
      else 'sitting red'
    end
  end

  def guest_status_text
    return '' if key == 0
    return '(Tyvärr är den här sittningen fullbokad)' if full?

    case guest_count
      when  0..8 then '(Det finns gott om plats)'
      when  9..15 then '(Det finns plats)'
      else red_status_text
    end
  end

  def red_status_text
    if free_seats < SEAT_COUNT_DOWN_THRESHOLD
     "(#{free_seats} plats#{free_seats > 1 ? 'er' : ''} kvar. Det kan bli lite trångt)"
    else
      "(Det kan bli lite trångt)"
    end
  end

  def free_seats
    (number_of_guests_allowed - number_of_reserved_seats) - guest_count
  end

  def full?
    return false if number_of_guests_allowed.nil?
    free_seats < 1
  end

  def seats_available?
    !full?
  end
end
