# encoding: UTF-8

class Guest
  inherit Mongo::Model

  collection "guests_#{Time.now.year}"

  attr_accessor :name, :company, :phone, :email
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
    s.nil? ? 'Ej valt' : s.title
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
end

