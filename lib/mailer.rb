require 'yajl'
require 'rest_client'

class Mailer
  def self.mail(from, to, subject, text, html, testmode = false)
    api_key = ENV['MAILGUN_API_KEY']

    response = '{ "error": "No Mailgun API key" }'

    unless api_key.nil?
      api_url = "https://api:#{api_key}@api.mailgun.net/v2/athega.mailgun.org"

      # Disable all emails
      testmode = true

      # Only enable real emails to a few accounts
      testmode = false if [
        'peter@c7.se',
        'torbjorn.nilsson@gmail.com',
        'mats.ygfors@seb.se',
        'christian.lizell@schibsted.se',
        'johan.beronius@athega.se',
        'mikael.forsberg@athega.se',
        'peter.hellberg@athega.se',
        'christian.lizell@athega.se',
        'torbjorn.nilsson@athega.se',
        'alex.robsahm@athega.se',
        'krister.soderstrom@athega.se',
        'mats.ygfors@athega.se',
        'petter.petersson@athega.se',
        'fredrik.soder@athega.se'
      ].include?(to)

      response = RestClient.post api_url+"/messages",
        :from => from,
        :to => to,
        :subject => subject,
        :text => text,
        :html => html,
        :'o:testmode' => testmode ? 'yes' : 'no'
    end

    Yajl::Parser.parse(response)
  end
end
