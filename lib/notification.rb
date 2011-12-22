# encoding: UTF-8

require 'yajl'

require_relative 'mailer'

class Notification

  def self.send_all_pending_invitations!
    # Config
    from     = 'athega@athega.se'
    subject  = 'Välkommen till Athegas Jullunch den 16/12'

    # Get the templates
    template = IO.read('views/notifications/invitation.haml')
    renderer = Haml::Engine.new(template).render_proc({}, :link, :name, :company, :invited_by)

    sent_count = 0

    Guest.not_invited_yet.not_invited_manually.sort([:company, 1], [:name, 1]).limit(30).each do |g|
      html = renderer.call link:       g.token_uri,
                           name:       g.name,
                           company:    g.company,
                           invited_by: g.invited_by

      text     = html.gsub(/<\/?[^>]*>/, "")
      response = Mailer.mail(from, g.email, subject, text, html)

      if response["message"] == "Queued. Thank you."
        g.invitation_email_sent = true
        g.save

        sent_count += 1
      end
    end

    sent_count
  end

  def self.send_all_pending_thank_you_notes!
    from     = 'athega@athega.se'
    subject  = 'Tack för senast'

    template = IO.read('views/notifications/thank_you.haml')
    renderer = Haml::Engine.new(template).render_proc({})

    sent_count = 0

    html = renderer.call
    text = html.gsub(/<\/?[^>]*>/, "")

    Guest.not_thanked_yet.arrived.where(company: { _ne: 'Vänner & Familj' }).limit(30).each do |g|
      response = Mailer.mail(from, g.email, subject, text, html)

      if response["message"] == "Queued. Thank you."
        g.thank_you_email_sent = true
        g.save

        sent_count += 1
      end
    end

    sent_count
  end
end
