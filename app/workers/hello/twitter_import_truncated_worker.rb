# frozen_string_literal: true

class Hello::TwitterImportTruncatedWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull'

  def perform(tweet_id)
    Rails.logger.info "Importing truncated tweet id=#{tweet_id}"
  end
end
