# frozen_string_literal: true

class Hello::TwitterTimelineScheduler
  include Sidekiq::Worker
  include Redisable

  sidekiq_options retry: 0, lock: :until_executed

  def perform
    last_tweet_id = redis.get('twitter_timeline_scheduler:last_tweet_id') || ''
    Rails.logger.info "Performing Scheduled Twitter Timeline since id #{last_tweet_id}..."
    last_last_tweet_id = Hello::TwitterTimeline.fetch_timeline(last_tweet_id)
    redis.set('twitter_timeline_scheduler:last_tweet_id', last_last_tweet_id)
  end
end
