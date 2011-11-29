class Guest
  inherit Mongo::Model

  collection "#{Time.now.year}_guests"

  attr_accessor :name, :company, :phone, :email
  attr_accessor :invited_by, :sitting, :status, :token
  attr_accessor :invited_manually

  def ftoken
    _id
  end
end

