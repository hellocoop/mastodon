# frozen_string_literal: true

class Hello::TwitterImportCompleteWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', retry: 2

  def perform(tweet)
    username = tweet['user']['screen_name']

    Rails.logger.info "Importing complete tweet #{tweet['id_str']} by #{username}: #{tweet['full_text']}"

    tweet_url = Hello::TwitterTimeline.create_tweet_url(tweet)

    if Status.find_by(url: tweet_url).present?
      Rails.logger.info "Tweet #{tweet['id_str']} already imported. Skipping."
      return
    end

    a = Account.find_by(username: username)

    if a.present?
      Status.create!(account: a, text: tweet['full_text'], language: 'en', url: tweet_url)
      Rails.logger.info "Tweet #{tweet['id_str']} imported."
    else
      Rails.logger.info "Tweet #{tweet['id_str']} cannot be imported. No corresponding account found: #{username}"
    end
  end
end
