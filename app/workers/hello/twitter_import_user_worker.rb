# frozen_string_literal: true

class Hello::TwitterImportUserWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', retry: 2

  def perform(user)
    screen_name = user['screen_name']

    Rails.logger.info "Importing user #{screen_name}: #{user['name']}, #{user['url']}"

    user_params = {
      'email' => "bot+#{screen_name}@verified.coop",
      'agreement' => true,
      'external' => true, # no password has to be set if external
      'account_attributes' => {
        'username' => screen_name,
        'display_name' => user['name'],
        'discoverable' => true,
        'hide_collections' => true,
        'note' => user['description'],
        'actor_type' => 'Service',
        'avatar_remote_url' => user['profile_image_url_https'],
        'header_remote_url' => user['profile_banner_url'],
        'fields' => [],
      },
    }

    if user['location'].present?
      user_params['account_attributes']['fields'].append({
        name: 'Location',
        value: user['location'],
      })
    end

    verified_at = Time.now.utc.iso8601

    user_params['account_attributes']['fields'].append({
      name: 'Twitter',
      value: "https://twitter.com/#{screen_name}",
      verified_at: verified_at,
    })

    if user['url'].present?
      user_params['account_attributes']['fields'].append({
        name: 'Website',
        value: user['url'],
        verified_at: verified_at,
      })
    end

    user = User.new(user_params)

    user.skip_confirmation!
    user.save!

    Rails.logger.info "Imported #{user['screen_name']}"
  end
end
