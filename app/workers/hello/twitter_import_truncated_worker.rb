# frozen_string_literal: true

class Hello::TwitterImportTruncatedWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', retry: 2

  def perform(tweet_id)
    Rails.logger.info "Importing truncated tweet id=#{tweet_id}"

    tweet = Hello::TwitterTimeline.fetch_tweet(tweet_id)

    Rails.logger.info "Fetched tweet #{tweet_id} (truncated: #{tweet['truncated']}) by #{tweet['user']['screen_name']}: #{tweet['text']}"

    Hello::TwitterImportCompleteWorker.perform_async(tweet)
  end
end
