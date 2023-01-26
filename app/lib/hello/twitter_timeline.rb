# frozen_string_literal: true

class Hello::TwitterTimeline

  def self.fetch_timeline(last_tweet_id)
    latest_tweet_id = last_tweet_id

    unless twitter_configured?
      Rails.logger.info 'Twitter not configured'
      return latest_tweet_id
    end

    since_id = ''
    if last_tweet_id.present?
      since_id = "&since_id=#{last_tweet_id}"
    end
    response = twitter_access_token.request(:get, "/1.1/statuses/home_timeline.json?tweet_mode=extended&count=200&exclude_replies=true#{since_id}")

    if response.code.to_i / 100 != 2
      Rails.logger.error "Twitter Timeline fetch failed with code #{response.code}: #{response.body}"
      return latest_tweet_id
    end

    rsp = JSON.parse(response.body)

    Rails.logger.info "Fetched #{rsp.size} entries"

    users_queued_for_import = []
    users_found = []

    count_non_en = 0
    count_truncated = 0
    count_complete = 0
    rsp.each do |tweet|
      user = tweet['user']
      username = user['screen_name']

      if users_queued_for_import.include?(username)
        next
      end

      unless users_found.include?(username)
        if user_exists?(username)
          users_found << username
        else
          Hello::TwitterImportUserWorker.perform_async(normalize_user(user))
          users_queued_for_import << username
        end
      end

      next unless users_found.include?(username)

      tweet_id = tweet['id']

      if tweet_id.to_i > latest_tweet_id.to_i
        latest_tweet_id = tweet_id
      end

      if tweet['lang'] == 'en'
        if tweet['truncated']
          Hello::TwitterImportTruncatedWorker.perform_async(tweet_id)
          count_truncated += 1
        else
          Hello::TwitterImportCompleteWorker.perform_async(normalize_tweet(tweet))
          count_complete += 1
        end
      else
        count_non_en += 1
      end
    end

    Rails.logger.info "Processed: #{count_complete} complete, #{count_truncated} truncated. Skipped: #{count_non_en} non English. Users: #{users_queued_for_import.size} queued for import, #{users_found.size} found."

    latest_tweet_id
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

  def self.user_exists?(username)
    Account.exists?(username: username, domain: nil)
  end

  def self.normalize_user(user)
    {
      'screen_name' => user['screen_name'],
      'name' => user['name'],
      'location' => user['location'],
      'created_at' => user['created_at'],
      'description' => normalize_user_description(user),
      'url' => normalize_user_url(user),
      'profile_image_url_https' => user['profile_image_url_https'],
      'profile_banner_url' => user['profile_banner_url'],
    }
  end

  def self.normalize_user_description(user)
    desc = user['description']

    if desc.present? && user['entities'].present? && user['entities']['description'].present? && user['entities']['description']['urls'].present?
      user['entities']['description']['urls'].each do |entity_url|
        short_url = entity_url['url']
        expanded_url = entity_url['expanded_url']

        if short_url.present? && expanded_url.present?
          desc.gsub!(short_url, expanded_url)
        end
      end
    end

    desc += "\n\n( account mirrored by https://verified.coop )"

    desc
  end

  def self.normalize_user_url(user)
    user_url = user['url']

    if user['entities'].present? && user['entities']['url'].present? && user['entities']['url']['urls'].present?
      user['entities']['url']['urls'].each do |entity_url|
        if entity_url['url'] == user_url
          return entity_url['expanded_url']
        end
      end
    end

    user_url
  end

  def self.normalize_tweet(tweet)
    {
      'id' => tweet['id'],
      'id_str' => tweet['id_str'],
      'full_text' => normalize_tweet_text(tweet),
      'user' => {
        screen_name: tweet['user']['screen_name'],
      },
    }
  end

  def self.normalize_tweet_text(tweet)
    text = tweet['full_text']

    if text.present?
      tweet['entities']['urls'].each do |entity_url|
        short_url = entity_url['url']
        expanded_url = entity_url['expanded_url']

        if short_url.present? && expanded_url.present?
          text.gsub!(short_url, expanded_url)
        end
      end
    end

    text
  end

  def self.create_tweet_url(tweet)
    return "https://twitter.com/#{tweet['user']['screen_name']}/status/#{tweet['id_str']}"
  end
end
