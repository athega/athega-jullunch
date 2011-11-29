# encoding: UTF-8

class Guest
  inherit Mongo::Model

  collection "#{Time.now.year}_guests"

  attr_accessor :name, :company, :phone, :email
  attr_accessor :invited_by, :sitting_key, :status, :token
  attr_accessor :invited_manually

  def has_checked_sitting?(sitting)
    sitting_key == sitting.key
  end
end

