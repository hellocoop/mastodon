# frozen_string_literal: true

class Hello::TwitterTimeline

  def self.fetch_timeline
    Rails.logger.info 'Fetching Twitter Timeline...'

    consumer = OAuth::Consumer.new(
      '4C7fZhKpIhvmcFzrc13EDg4ca',
      'XmTUALj9URHpLLj17nurZv5FpruyBUoyd2BUOugRMh5R2hvafX',
      site: "https://api.twitter.com"
    )

    access_token = OAuth::AccessToken.new(
      consumer,
      '1606402079576424448-CcdZzYxdh8cdS6JkiCtv9KZgjGc9LX',
      'CCPrMfuUgC9q5G8HbXqnXECoRkAmA0yr0GAI0TH7dNRb5'
    )

    response = access_token.request(:get, '/1.1/statuses/home_timeline.json')
    rsp = JSON.parse(response.body)

    # Rails.logger.info rsp
  end
end
