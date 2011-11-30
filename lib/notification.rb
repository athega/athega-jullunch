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
    renderer = Haml::Engine.new(template).render_proc({}, :link, :name, :company)

    sent_count = 0

    Guest.where(invited_manually: true).each do |g|
      html = renderer.call link: g.token_uri, name: g.name, company: g.company
      text = html.gsub(/<\/?[^>]*>/, "")

      response    = Mailer.mail(from, g.email, subject, text, html)
      sent_count += 1 if response["message"] == "Queued. Thank you."
    end

    sent_count
  end

  def self.send_all_pending_reminders!
  end
end
