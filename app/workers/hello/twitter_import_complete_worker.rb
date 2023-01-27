# frozen_string_literal: true

class Hello::TwitterImportCompleteWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', retry: 1

  def perform(tweet)
    username = tweet['user']['screen_name']

    Rails.logger.info "Importing complete tweet #{tweet['id_str']} by #{username}: #{tweet['full_text']}"

    a = Account.find_by(username: username)

    media_ids = []

    if a.present?
      if tweet.dig('entities', 'media').present?
        tweet['entities']['media'].each do |entity_url|
          Rails.logger.info "Importing media attachment #{entity_url['media_url_https']}"

          m = MediaAttachment.create(
            account: a,
            remote_url: entity_url['media_url_https']
          )
          m.download_file!
          m.save

          media_ids << m.id
        end
      end

      status = PostStatusService.new.call(
        a,
        text: tweet['full_text'],
        media_ids: media_ids,
        language: 'en',
        idempotency: "tweet:#{tweet['id_str']}"
      )

      if status.present?
        Rails.logger.info "Tweet #{tweet['id_str']} imported."
      else
        Rails.logger.info "Tweet #{tweet['id_str']} not imported."
      end
    else
      Rails.logger.info "Tweet #{tweet['id_str']} cannot be imported. No corresponding account found: #{username}"
    end
  end
end
