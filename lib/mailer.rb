require 'rest_client'

class Mailer
  def self.mail(from, to, subject, text, html, o_testmode = 'yes')

    api_key = ENV['MAILGUN_API_KEY']
    api_url = "https://api:#{api_key}@api.mailgun.net/v2/athega.mailgun.org"

    RestClient.post api_url+"/messages",
      :from => from,
      :to => to,
      :subject => subject,
      :text => text,
      :html => html,
      :'o:testmode' => o_testmode
  end
end
