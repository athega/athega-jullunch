require 'yajl'
require 'rest_client'

class Mailer
  def self.mail(from, to, subject, text, html, o_testmode = 'yes')
    api_key = ENV['MAILGUN_API_KEY']

    response = '{ "error": "No Mailgun API key" }'

    unless api_key.nil?
      api_url = "https://api:#{api_key}@api.mailgun.net/v2/athega.mailgun.org"

      response = RestClient.post api_url+"/messages",
        :from => from,
        :to => to,
        :subject => subject,
        :text => text,
        :html => html,
        :'o:testmode' => o_testmode
    end

    Yajl::Parser.parse(response)
  end
end
