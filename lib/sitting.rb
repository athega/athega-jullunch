# encoding: UTF-8

class Sitting
  inherit Mongo::Model

  collection "sittings_#{Time.now.year}"

  attr_accessor :title, :key, :starts_at

  validates_numericality_of :key
  validates_presence_of :title

  def local_time
    starts_at.nil? ? '' : starts_at.getlocal
  end

  def guest_count
    @guest_count ||= Guest.all_by_sitting(key).count
  end

  def guest_status_class
    return 'sitting' if key == 0

    case guest_count
      when  0..10 then 'sitting green'
      when 11..20 then 'sitting yellow'
      else 'sitting red'
    end
  end

  def guest_status_text
    return '' if key == 0

    case guest_count
      when  0..10 then '(Det finns gott om plats)'
      when 11..20 then '(Det finns plats)'
      else '(Det kan bli lite trångt)'
    end
  end
end
