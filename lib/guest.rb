# encoding: UTF-8

class Guest
  inherit Mongo::Model

  collection "guests_#{Time.now.year}"

  attr_accessor :name, :company, :email, :image_url
  attr_accessor :invited_by, :sitting_key, :status, :token
  attr_accessor :invited_manually, :invitation_email_sent, :reminder_email_sent
  attr_accessor :arrived, :arrived_at

  scope :invited_manually, invited_manually: true
  scope :not_invited_manually, invited_manually: false

  scope :not_invited_yet,  invitation_email_sent: false, invited_manually: false
  scope :not_reminded_yet, reminder_email_sent: false, invited_manually: false
  scope :not_arrived_yet,  arrived:  false, sitting_key: { _in: [1130, 1200, 1230, 1300, 1330] }

  scope :invited,  invitation_email_sent: true
  scope :reminded, reminder_email_sent: true
  scope :arrived,  arrived:  true

  validates_presence_of :name
  validates_presence_of :company
  validates_presence_of :email
  validates_presence_of :invited_by

  def has_checked_sitting?(sitting)
    sitting_key == sitting.key
  end

  def thumbnail_url
    image_url.gsub('hatified', 'thumb')
  end

  def sitting
    s = Sitting.by_key(sitting_key)

    if s.nil?
      'Ej valt'
    else
      declined? ? 'Nej' : s.title
    end
  end

  def status_string
    output = 'Inte fått inbjudan än'

    if invitation_email_sent
      output  = 'Fått inbjudan'
      output += ', blivit påmind' if reminder_email_sent
      output += ' och har dykt upp på Jullunchen' if arrived
    end

    output
  end

  def css_classes
    "guest #{sitting_class} #{invite_class}"
  end

  def declined?
    sitting_key == 0
  end

  def token_uri
    "http://jullunch.athega.se/?token=#{token}"
  end

  protected

  def set_default_values
    @token                  = _id if @token.nil?
    @invited_manually       = false if @invited_manually.nil?
    @invitation_email_sent  = false
    @reminder_email_sent    = false
    @arrived                = false

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

