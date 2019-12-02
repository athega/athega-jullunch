# encoding: UTF-8

class Guest
  include Mongoid::Document
  include Mongoid::Token

  store_in collection: "guests_#{Time.now.year}"

  field :name
  field :company
  field :email
  field :image_url

  field :invited_by
  field :sitting_key
  field :status

  field :invited_manually, default: false
  field :invitation_email_sent, default: false
  field :reminder_email_sent, default: false
  field :welcome_email_sent, default: false
  field :thank_you_email_sent, default: false

  field :arrived, default: false
  field :arrived_at
  field :departed, default: false
  field :departed_at

  field :rfid
  field :mulled_wine, default: 0
  field :food, default: 0
  field :drink, default: 0
  field :coffee, default: 0

  scope :invited_manually,     -> { where(invited_manually: true) }
  scope :not_invited_manually, -> { where(invited_manually: false) }
  scope :not_rsvped,           -> { where(sitting_key: nil) }

  scope :not_invited_yet,  -> { where(invitation_email_sent: false, invited_manually: false) }
  scope :not_arrived_yet,  -> { where(arrived: false).in(sitting_key: [1130, 1200, 1230, 1300, 1330, 1600]) }
  scope :not_reminded_yet, -> { where(reminder_email_sent: false) }
  scope :not_welcomed_yet, -> { where(welcome_email_sent: false) }
  scope :not_thanked_yet,  -> { where(thank_you_email_sent: false) }

  scope :arrived,  -> { where(arrived: true) }
  scope :departed, -> { where(departed: true) }
  scope :invited,  -> { where(invitation_email_sent: true) }
  scope :welcomed, -> { where(welcome_email_sent: true) }
  scope :thanked,  -> { where(thank_you_email_sent: true) }
  scope :said_yes, -> { where(:sitting_key.in => [1130, 1200, 1230, 1300, 1330, 1600]) }

  scope :untagged, -> { where(rfid: nil) }

  validates :name, presence: true
  validates :company, presence: true
  validates :email, presence: true
  validates :invited_by, presence: true

  token :length => 5

  def has_checked_sitting?(sitting)
    sitting_key == sitting.key
  end

  def thumbnail_url
    image_url.nil? ? '' : image_url.gsub('hatified', 'thumb')
  end

  def sitting
    s = Sitting.find_by(key: sitting_key)

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
      output += ', blivit välkomnad' if welcome_email_sent
      output += ', blivit tackad' if thank_you_email_sent
      output += ', har dykt upp' if arrived
      output += ' och lämnat jullunchen' if departed
    end

    output
  end

  def css_classes
    "guest #{sitting_class} #{invite_class}"
  end

  def declined?
    sitting_key == 0
  end

  def coming?
    !sitting_key.nil? && sitting_key > 0
  end

  def token_uri
    "http://jullunch.athega.se/?token=#{token}"
  end

  protected

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

