# frozen_string_literal: true

require 'securerandom'

class Hello::TwitterImportUserWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull'

  def perform(user)
    Rails.logger.info "Importing user #{user['screen_name']}: #{user['name']}, #{user['description']}, #{user['url']}"

    user_params = {
      email: "bot+#{user['screen_name']}@verified.coop",
      agreement: true,
      external: false,
      password: SecureRandom.hex,
      account_attributes: {
        username: user['screen_name'],
        display_name: user['name'],
        discoverable: true,
        hide_collections: true,
        note: user['description'],
        actor_type: 'Service',
        avatar_remote_url: user['profile_image_url_https'],
        header_remote_url: user['profile_banner_url'],

        # TODO where should user['url'] go?
        # uri: '',
        # url: '',
      },
    }

    user = User.new(user_params)

    user.skip_confirmation!
    user.save!

    Rails.logger.info "Imported #{user['screen_name']}"
  end
end
