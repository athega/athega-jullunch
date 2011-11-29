# encoding: UTF-8

class Guest
  inherit Mongo::Model

  collection "guests_#{Time.now.year}"

  attr_accessor :name, :company, :phone, :email
  attr_accessor :invited_by, :sitting_key, :status, :token
  attr_accessor :invited_manually

  validates_presence_of :name
  validates_presence_of :company
  validates_presence_of :email
  validates_presence_of :invited_by

  def has_checked_sitting?(sitting)
    sitting_key == sitting.key
  end
end

