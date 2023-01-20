# frozen_string_literal: true

class Hello::TwitterTimeline

  def self.fetch_timeline
    Rails.logger.info 'Fetching Twitter Timeline...'

    response = twitter_access_token.request(:get, '/1.1/statuses/home_timeline.json')
    rsp = JSON.parse(response.body)

    Rails.logger.info "Fetched #{rsp.size} entries"

    count_non_en = 0
    count_truncated = 0
    count_complete = 0
    rsp.each do |tweet|
      if tweet['lang'] == 'en'
        if tweet['truncated']
          Hello::TwitterImportTruncatedWorker.perform_async(tweet['id'])
          count_truncated += 1
        else
          Hello::TwitterImportCompleteWorker.perform_async(tweet)
          count_complete += 1
        end
      else
        count_non_en += 1
      end
    end

    Rails.logger.info "Processed: #{count_complete} complete, #{count_truncated} truncated. Skipped: #{count_non_en} non English."
  end

  def self.fetch_tweet(tweet_id)
    response = twitter_access_token.request(:get, "/1.1/statuses/show.json?id=#{tweet_id}")

    JSON.parse(response.body)
  end

  def self.twitter_access_token
    consumer = OAuth::Consumer.new(
      ENV['TWITTER_CONSUMER_KEY'],
      ENV['TWITTER_CONSUMER_SECRET'],
      site: 'https://api.twitter.com'
    )

    OAuth::AccessToken.new(
      consumer,
      ENV['TWITTER_ACCESS_TOKEN'],
      ENV['TWITTER_ACCESS_TOKEN_SECRET']
    )
  end
end
