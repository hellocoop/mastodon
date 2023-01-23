# frozen_string_literal: true

class Hello::TwitterTimeline

  def self.fetch_timeline
    unless twitter_configured?
      Rails.logger.info 'Twitter not configured'
      return
    end

    Rails.logger.info 'Fetching Twitter Timeline...'

    response = twitter_access_token.request(:get, '/1.1/statuses/home_timeline.json?tweet_mode=extended')

    if response.code != "200"
      Rails.logger.error "Twitter Timeline fetch failed with code #{response.code}: #{response.body}"
      return
    end

    rsp = JSON.parse(response.body)

    Rails.logger.info "Fetched #{rsp.size} entries"

    count_non_en = 0
    count_truncated = 0
    count_complete = 0
    rsp.each do |tweet|
      user = tweet['user']

      if user_exists?(user)
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
      else
        Hello::TwitterImportUserWorker.perform_async(user)
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

  def self.twitter_configured?
    ENV['TWITTER_CONSUMER_KEY'].present? && ENV['TWITTER_CONSUMER_SECRET'].present? && ENV['TWITTER_ACCESS_TOKEN'].present? && ENV['TWITTER_ACCESS_TOKEN_SECRET'].present?
  end

  def self.user_exists?(user)
    true # TODO
  end
end
