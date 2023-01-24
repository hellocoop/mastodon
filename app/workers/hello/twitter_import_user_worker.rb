# frozen_string_literal: true

class Hello::TwitterImportUserWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull'

  def perform(user)
    Rails.logger.info "Importing user #{user['screen_name']}: #{user['name']}, #{user['description']}, #{user['url']}"

    user_params = {
      email: "bot+#{user['screen_name']}@verified.coop",
      agreement: true,
      external: true, # no password has to be set if external
      account_attributes: {
        username: user['screen_name'],
        display_name: user['name'],
        discoverable: true,
        hide_collections: true,
        note: user['description'],
        actor_type: 'Service',
        avatar_remote_url: user['profile_image_url_https'],
        header_remote_url: user['profile_banner_url'],
        fields: [
          {
            name: 'Home',
            value: user['url'],
            verified_at: Time.now.utc.iso8601,
          },
        ],
      },
    }

    user = User.new(user_params)

    user.skip_confirmation!
    user.save!

    Rails.logger.info "Imported #{user['screen_name']}"
  end
end
