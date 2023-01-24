# frozen_string_literal: true

class Hello::TwitterImportCompleteWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull'

  def perform(tweet)
    Rails.logger.info "Importing complete tweet id=#{tweet['id']} by #{tweet['user']['screen_name']}: #{tweet['full_text']}"
  end
end
