# frozen_string_literal: true

class Hello::TwitterImportUserWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull'

  def perform(user)
    Rails.logger.info "Importing user #{user['screen_name']}: #{user['name']}"
  end
end
