# encoding: UTF-8

class Guest
  inherit Mongo::Model

  collection "guests_#{Time.now.year}"

  attr_accessor :name, :company, :email
  attr_accessor :invited_by, :sitting_key, :status, :token
  attr_accessor :invited_manually, :notified, :reminded, :arrived

  validates_presence_of :name
  validates_presence_of :company
  validates_presence_of :email
  validates_presence_of :invited_by

  def has_checked_sitting?(sitting)
    sitting_key == sitting.key
  end

  def sitting
    s = Sitting.by_key(sitting_key)

    if s.nil?
      'Ej valt'
    else
      declined? ? 'Nej' : s.title
    end
  end

  def css_classes
    "guest #{sitting_class} #{invite_class}"
  end

  def declined?
    sitting_key == 0
  end

  protected

  def set_default_values
    @token = _id if @token.nil?
    @notified = false
    @reminded = false
    @arrived  = false

    save
  end

  after_create :set_default_values

  private

  def sitting_class
    {
      0    => 'declined',
      1130 => 'sitting-1130',
      1200 => 'sitting-1200',
      1230 => 'sitting-1230',
      1300 => 'sitting-1300',
      1330 => 'sitting-1330'
    }[sitting_key] || 'no-response'
  end

  def invite_class
    invited_manually == true ? 'manual' : 'auto'
  end
end

