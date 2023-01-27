# frozen_string_literal: true

class Hello::TwitterImportCompleteWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', retry: 1

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
      status = PostStatusService.new.call(a, text: tweet['full_text'], language: 'en', idempotency: tweet['id_str'])

      if status.present?
        status.url = tweet_url
        status.save!

        Rails.logger.info "Tweet #{tweet['id_str']} imported."
      else
        Rails.logger.info "Tweet #{tweet['id_str']} not imported."
      end
    else
      Rails.logger.info "Tweet #{tweet['id_str']} cannot be imported. No corresponding account found: #{username}"
    end
  end
end
