# encoding: UTF-8

class Guest
  inherit Mongo::Model

  collection "guests_#{Time.now.year}"

  attr_accessor :name, :company, :phone, :email
  attr_accessor :invited_by, :sitting_key, :status, :token
  attr_accessor :invited_manually, :notified, :reminded

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
    @notified = false
    @reminded = false
  end

  def set_token
    if @token.nil?
      @token = _id
      save
    end
  end

  before_create :set_default_values
  after_create  :set_token
end

