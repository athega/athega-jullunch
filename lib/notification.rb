# encoding: utf-8

require 'yajl'

require_relative 'mailer'

class Notification

  def self.send_all_pending_invitations!
    # Config
    from     = 'athega@athega.se'
    subject  = 'Välkommen till Athegas jullunch'

    # Get the templates
    template = IO.read('views/notifications/invitation.haml')
    renderer = Haml::Engine.new(template).render_proc({}, :link, :name, :company, :invited_by)

    sent_count = 0

    Guest.not_invited_yet.not_invited_manually.order_by(:company.asc, :name.asc).limit(30).each do |g|
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

  def self.send_all_pending_reminders!
    # Config
    from     = 'athega@athega.se'
    subject  = 'Du har väl inte missat att det är dags för Athegas jullunch?'

    # Get the templates
    template = IO.read('views/notifications/reminder.haml')
    renderer = Haml::Engine.new(template).render_proc({}, :link, :name, :company, :invited_by)

    sent_count = 0

    Guest.not_reminded_yet.not_rsvped.order_by(:company.asc, :name.asc).limit(30).each do |g|
      html = renderer.call link:       g.token_uri,
                           name:       g.name,
                           company:    g.company,
                           invited_by: g.invited_by

      text     = html.gsub(/<\/?[^>]*>/, "")

      response = Mailer.mail(from, g.email, subject, text, html)

      if response["message"] == "Queued. Thank you."
        g.reminder_email_sent = true
        g.save
        sent_count += 1
      end
    end
    sent_count
  end

  def self.send_all_pending_welcomes!
    # Config
    from     = 'athega@athega.se'
    subject  = 'Kul att du vill komma på Athegas jullunch'

    # Get the templates
    template = IO.read('views/notifications/welcome.haml')
    renderer = Haml::Engine.new(template).render_proc({}, :name, :company, :invited_by, :sitting)

    sent_count = 0

    Guest.said_yes.not_welcomed_yet.order_by(:company.asc, :name.asc).limit(30).each do |g|
      html = renderer.call name:       g.name,
                           company:    g.company,
                           invited_by: g.invited_by,
                           sitting:    g.sitting

      text     = html.gsub(/<\/?[^>]*>/, "")
      response = Mailer.mail(from, g.email, subject, text, html)

      if response["message"] == "Queued. Thank you."
        g.welcome_email_sent = true
        g.save

        sent_count += 1
      end
    end

    sent_count
  end

  def self.send_all_pending_thank_you_notes!
    from     = 'athega@athega.se'
    subject  = 'Med önskan om en God Jul'

    template = IO.read('views/notifications/thank_you.haml')
    renderer = Haml::Engine.new(template).render_proc({}, :mulled_wine, :food, :coffee, :drink, :image_url)

    sent_count = 0

    Guest.not_thanked_yet.arrived.where(:company.ne => 'Vänner & Familj').limit(30).each do |g|
      html = renderer.call mulled_wine: g.mulled_wine,
                           food:        g.food,
                           coffee:      g.coffee,
                           drink:       g.drink,
                           image_url:   g.image_url

      text = html.gsub(/<\/?[^>]*>/, "")
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
